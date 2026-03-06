// ============================================================================
// OFFLINE MODE - IMPLEMENTATION GUIDE
// ============================================================================
//
// Sistem koji omogućava korisnicima da koriste app bez interneta
// i automatski sinhronizuje porudžbine kada se vrate online
//
// ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════
ARHITEKTURA
═══════════════════════════════════════════════════════════════════════════

ConnectivityService
  └─ Prati internet status (online/offline)

OrderQueueService
  └─ Čuva porudžbine offline u lokalu (SharedPreferences)
  └─ PendingOrder model sa timestamp-ovima

SyncManager
  └─ Automatski sinhronizuje pending porudžbine kada je online
  └─ Listens na ConnectivityService za promene

AppState
  └─ Integriše sve tri komponente
  └─ Expose-a isOnline/isOffline flage

UI Widgets
  └─ OfflineIndicator - banner kada je offline
  └─ OfflineSnackBar - notifikacija
  └─ OfflineReadOnlyBadge - označava read-only mode

═══════════════════════════════════════════════════════════════════════════
*/

// ============================================================================
// SCENARIJO: KORISNIK KUPUJE OFFLINE
// ============================================================================

/*
1. Korisnik pregledava proizvodi (offline)
   └─ HomeScreen učitava iz cache-a (ranije pohvaćeni podaci)
   └─ ProductDetailScreen prikazuje iz cache-a
   └─ OfflineIndicator banner: "Nemaš internet..."

2. Korisnik dodaj u cart (offline)
   └─ CartProvider nastavlja da radi normalno
   └─ Local persistence je vec aktivan

3. Korisnik ide na checkout (offline)
   └─ CheckoutScreen detektuje offline mode
   └─ ShowData: OfflineReadOnlyBadge umesto "Submit Order"
   └─ Prikazuje: "Porudžbina će biti poslata automatski kada..."
   └─ Ili: "Očekuj internet da pošalješ porudžbinu"

4. Korisnik čeka internet (offline)
   └─ App čuva draft porudžbine u OrderQueueService
   └─ SyncManager čeka da ConnectivityService detektuje online

5. Internet se vrati (online)
   └─ ConnectivityService detektuje promenu
   └─ SyncManager automatski:
      ├─ Pokuša slati sve pending porudžbina
      ├─ Ako uspede, označi kao synced
      ├─ Ako fail, čuva za sledeći pokušaj
   └─ Toast "Porudžbine poslate! Hvala na kupovini"

═══════════════════════════════════════════════════════════════════════════
*/

// ============================================================================
// KAKO KORISTITI U KODU
// ============================================================================

// 1. PROVERITE OFFLINE STATUS

import 'package:provider/provider.dart';
import 'providers/app_state.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<AppState>().isOffline;

    if (isOffline) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('Nemaš internet'),
            ElevatedButton(
              onPressed: () {
                // Korisnik može da nastavi sa offline browsing
              },
              child: Text('Nastavi pregledanje'),
            ),
          ],
        ),
      );
    }

    return NormalContent();
  }
}

// ============================================================================

// 2. DODAJ PORUDŽBINU U QUEUE (OFFLINE)

class CheckoutScreen extends StatefulWidget {
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Future<void> _submitOrder() async {
    final appState = context.read<AppState>();
    final isOffline = appState.isOffline;

    if (isOffline) {
      // Kreiraj PendingOrder sa datumima
      final pendingOrder = PendingOrder(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        buyerId: userId,
        sellerId: sellerId,
        productId: productId,
        productName: productName,
        quantityKg: quantity,
        unitType: unitType,
        note: note,
        buyerCity: city,
        buyerAddress: address,
        buyerPhone: phone,
        preferCall: preferCall,
        pickupOptions: pickupOptions,
        createdAt: DateTime.now(),
      );

      // Dodaj u offline queue
      await appState.orderQueue.addPendingOrder(pendingOrder);

      // Prikaži potvrdu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Porudžbina je sačuvana! Biće poslana kada se povežeš.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      // Slanje na server kao normalno
      try {
        final orderId = await ordersService.createOrder(...);
        // Success
      } catch (e) {
        // Error - prikaži ErrorDialog
      }
    }
  }
}

// ============================================================================

// 3. MONITOR SYNC STATUS

class OrdersScreen extends StatefulWidget {
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final syncManager = context.watch<AppState>().syncManager;
    final isSyncing = syncManager.isSyncing;
    final syncError = syncManager.syncError;
    final syncedCount = syncManager.syncedCount;

    return Scaffold(
      appBar: AppBar(title: Text('Moje porudžbine')),
      body: Stack(
        children: [
          // Content
          ListView(...),

          // Sync indicator
          if (isSyncing)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Sinhronizuje offline porudžbine...'),
                    ],
                  ),
                ),
              ),
            ),

          // Sync error
          if (syncError != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sinhronizacija pala: $syncError',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => appState.syncManager.syncPendingOrders(),
                        child: Text('Pokušaj ponovno'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================

// 4. MANUALNA SINHRONIZACIJA

class ManualSyncExample {
  void triggerSync(BuildContext context) {
    final syncManager = context.read<AppState>().syncManager;
    
    // Pokreni sinhronizaciju ručno
    syncManager.syncPendingOrders().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sinhronizacija završena!')),
      );
    });
  }
}

// ============================================================================
// DATA FLOW
// ============================================================================

/*
ONLINE:
  User checkout
    ↓
  OrdersService.createOrder() [direct to Supabase]
    ↓
  Success/Error

OFFLINE:
  User checkout
    ↓
  OrderQueueService.addPendingOrder() [save to SharedPreferences]
    ↓
  ShowToast: "Porudžbina će biti poslata..."
    ↓
  ConnectivityService detektuje internet
    ↓
  SyncManager.syncPendingOrders()
    ↓
  OrdersService.createOrder() [send to Supabase]
    ↓
  OrderQueueService.markAsSynced()
    ↓
  Show notification "Porudžbine poslate"

═══════════════════════════════════════════════════════════════════════════
*/

// ============================================================================
// TESTING OFFLINE MODE
// ============================================================================

/*
1. DevTools Network Throttling:
   - DevTools → Network → Offline
   - App treba automatski promeniti na offline mode
   - OfflineIndicator banner trebao bi biti vidljiv

2. HomeScreen:
   - Data trebalo bi da bude iz cache-a (preuzeto ranije)
   - ili "No data cached" poruka

3. ProductDetail:
   - Prikaži cached podatke ako su dostupni
   - Ili "Loading from cache..."

4. Checkout:
   - Prikaži draft porudžbine kao "Pending"
   - Imajte dugme za retry kada se internet vrati

5. Cart:
   - Trebalo bi nastaviti da radi normalno
   - Persistence je već aktivan

6. Vrati internet:
   - Zatvori airplane mode ili vrati internet
   - SyncManager trebao bi automatski pokrenuti sinhronizaciju
   - Prikaži toast "Offline porudžbine su poslate"

═══════════════════════════════════════════════════════════════════════════
*/

// ============================================================================
// GOTCHA-S I EDGE CASES
// ============================================================================

/*
1. Stara podaci (cache):
   - Što ako je proizvod brisan na serveru?
   - Solution: Pri sinhronizaciji, proverite da li proizvod postoji

2. Duplikat porudžbina:
   - Što ako korisnik submituje više vremena?
   - Solution: Koristi unique order ID-ove sa timestamp-ovana

3. Promenljive cene:
   - Što ako se cena promenila dok je offline?
   - Solution: Pri sinhronizaciji, prikaži dialoga: "Cena se promenila"

4. Baterjija:
   - Sync trebalo bi biti lightweight
   - Solution: Batching - pošalji sve 10 porudžbina odjednom

5. Storage limit:
   - Što ako korisnik ima 100 (pending porudžbina?
   - Solution: Limit na 50 pending orders, starije obriši
   (ili warn korisnika)

═══════════════════════════════════════════════════════════════════════════
*/

// ============================================================================
// BUDUĆE POBOLJŠANJA
// ============================================================================

/*
1. Optimistic UI:
   - Prikaži porudžbinu kao "Submitted" dok čekaj sync
   - Ako fail, prikaži error sa retry

2. Offline Map:
   - Cache map podatke za seller locations
   - Prikaži offline mapu

3. Offline Search:
   - Prikaži recent searches offline
   - Ili local product index

4. Background Sync:
   - WorkManager za sinhronizaciju na app restart
   - NotificationChannel za "Porudžbine poslate" notifikacija

5. Conflict Resolution:
   - Šta ako je order već dostavljeno dok je offline?
   - Prikaži dialoga: "Ova porudžbina je već dostavljena"
   - Obriši iz offline queue

═══════════════════════════════════════════════════════════════════════════
*/
