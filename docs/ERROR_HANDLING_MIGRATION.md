// ============================================================================
// MIGRATION GUIDE - KAKO UPDATEOVATI EXISTING SERVICES
// ============================================================================
//
// Ovaj guide pokazuje kako da migriraš postojeće servise na novi error
// handling sistem.
//
// ============================================================================

// ============================================================================
// PRIMER 1: PRODUCTS_SERVICE - GETPRODUCTSPAGE
// ============================================================================

// STARI KOD:
//
// Future<({List<ProductModel> items, bool hasMore, Map<String, int> salesCounts})>
//     getProductsPage(...) async {
//   try {
//     const table = 'products_with_ratings';
//     var query = _client.from(table).select();
//     // ... query building ...
//     final list = await ordered.range(offset, offset + limit - 1);
//     final rows = list as List;
//     final products = rows
//         .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
//         .toList();
//     final salesCounts = <String, int>{};
//     // ...
//     return (items: products, hasMore: true, salesCounts: salesCounts);
//   } catch (e) {
//     debugPrint('Error loading products: $e');  // ❌ LOŠE!
//     rethrow;
//   }
// }

// NOVI KOD:
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger_service.dart';
import 'error_handler_service.dart';
import '../models/app_error.dart';

// Future<({List<ProductModel> items, bool hasMore, Map<String, int> salesCounts})>
//     getProductsPage(...) async {
//   return ErrorHandlerService().executeWithRetry(
//     'Load products page (offset: $offset, limit: $limit)',
//     () async {
//       const table = 'products_with_ratings';
//       var query = _client.from(table).select();
//       // ... query building ...
//       final list = await ordered.range(offset, offset + limit - 1);
//       final rows = list as List;
//       final products = rows
//           .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
//           .toList();
//       final salesCounts = <String, int>{};
//       // ...
//       return (items: products, hasMore: true, salesCounts: salesCounts);
//     },
//     maxRetries: 2,
//     shouldRetry: (error) => error.isNetworkError || error.isTimeout,
//   );
// }

// BENEFITI:
// ✓ Automatski retry na network greške
// ✓ Proper logging sa detaljima
// ✓ User vidi šta se dešava (timeout, network, itd)
// ✓ Can be tested easily

// ============================================================================
// PRIMER 2: PUSH_SERVICE - REGISTER TOKEN
// ============================================================================

// STARI KOD:
//
// Future<void> registerToken(String userId) async {
//   if (kIsWeb) return;
//   try {
//     final granted = await ensureNotificationPermission();
//     // ...
//     await _client.from('user_push_tokens').upsert([...]);
//   } catch (e) {
//     debugPrint('PushService registerToken: $e');  // ❌ Šta se sleži?
//   }
// }

// NOVI KOD:
//
// Future<void> registerToken(String userId) async {
//   if (kIsWeb) return;
//   try {
//     final granted = await ensureNotificationPermission();
//     // ...
//     await _client.from('user_push_tokens').upsert([...]);
//   } catch (e, st) {
//     // Kreiraj AppError sa context-om
//     final error = AppError.from(
//       e,
//       stackTrace: st,
//       userMessage: 'Nije moguće registrovati push notifikacije. Pokušaj kasnije.',
//     );
//
//     // Log sa detaljima
//     LoggerService.error('Failed to register push token', e, stackTrace: st, extra: {
//       'userId': userId,
//       'errorType': error.type.toString(),
//     });
//
//     // Prosled ErrorHandlerService-u za analytics/crash reporting
//     await ErrorHandlerService().handleError(e, stackTrace: st);
//     // NE rethrow-uj jer je ovo non-critical - app može nastaviti bez push-a
//   }
// }

// ============================================================================
// PRIMER 3: CART_PROVIDER - LOAD
// ============================================================================

// STARI KOD:
//
// Future<void> _load() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final stored = prefs.getString(_storageKey);
//     if (stored != null && stored.isNotEmpty) {
//       // ... parsing ...
//     }
//   } catch (e) {
//     if (kDebugMode) debugPrint('CartProvider _load: $e');  // ❌ Debug-only!
//   }
// }

// NOVI KOD:
//
// Future<void> _load() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final stored = prefs.getString(_storageKey);
//     if (stored != null && stored.isNotEmpty) {
//       // ... parsing ...
//     }
//   } catch (e, st) {
//     LoggerService.warning('Failed to load cart from storage', extra: {
//       'error': e.toString(),
//       'storedLength': stored?.length,
//     });
//     // Nastavi sa praznom cart-om, ne rethrow jer je non-critical
//     return;
//   }
// }

// ============================================================================
// MIGRATION CHECKLIST
// ============================================================================

/*
Kada migriraš service, sledi ove korake:

□ 1. Dodaj imports na početak fajla:
   import 'logger_service.dart';
   import 'error_handler_service.dart';

□ 2. Pretrazi sve `catch (_)` i `catch (e)`
   grep "catch (" services/my_service.dart

□ 3. Za svaki catch blok, odredi:
   - Da li je kritično? (trebam li rethrow?)
   - Da li trebam retry? (network, timeout)
   - Šta korisnik vidi?
   - Da li trebam extra info u log?

□ 4. Zameni catch bloke sa:
   
   // Za kritične операciјe (trebam retry):
   return ErrorHandlerService().executeWithRetry(
     'Operation label',
     () => operation(),
     shouldRetry: (error) => error.isNetworkError || error.isTimeout,
   );
   
   // Za manje bitne operacije (samo log):
   try {
     await operation();
   } catch (e, st) {
     LoggerService.warning('Operation failed', extra: {
       'error': e.toString(),
       'otherInfo': value,
     });
   }

□ 5. Test sa:
   - Flutter run u debug modu
   - Simuliraj network greške (throttle / offline)
   - Proveri LoggerService output

□ 6. Proveri da li UI pravilno prikazuje greške:
   - ErrorDialog za kritične greške
   - ErrorSnackBar za manje greške
   - Loading state sa spinning circle
*/

// ============================================================================
// ERROR TYPES - DECISION TREE
// ============================================================================

/*
Kada se javi greška, sledi ovaj decision tree:

1. Šta je greška?
   ├─ Network greška?
   │  └─ executeWithRetry() sa shouldRetry: (e) => e.isNetworkError
   ├─ Timeout?
   │  └─ executeWithRetry() sa shouldRetry: (e) => e.isTimeout
   ├─ Validation greška?
   │  └─ Log i prikaži user error message
   ├─ Authorization greška (401)?
   │  └─ Log i zatraži login ponovno
   └─ Nešto drugo?
      └─ Log sa full stackTrace i prikaži generic message

2. Trebam li retry?
   ├─ Network / Timeout → DA
   ├─ Server error (5xx) → MOŽDA (sa back-off strategijom)
   ├─ Validation / Auth / Conflict → NE
   └─ Unknown → NE (samo log)

3. Šta korisnik vidi?
   ├─ Network greška → ErrorSnackBar sa "Retry" dugme
   ├─ Timeout → ErrorDialog sa "Try again" dugme
   ├─ Validation greška → Isti ekran sa error porukom na polju
   ├─ Auth → Redirect na login
   └─ Ostalo → Generic error dialog (bez "Retry" dugme)
*/

// ============================================================================
// PRIMERI IZ STVARNOG KODA
// ============================================================================

// PRIMER: Orders Service - fetchOrdersByBuyer

/*
// STARI KOD:
Future<List<OrderModel>> _fetchOrdersByBuyer(
  String buyerId, {
  int limit = _kPageSize,
  int offset = 0,
  String? statusFilter,
}) async {
  var query = _client.from('orders').select().eq('buyer_id', buyerId);
  if (statusFilter != null && statusFilter.isNotEmpty) {
    query = query.eq('status', statusFilter);
  }
  final list = await query
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1);
  final orders = (list as List)
      .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return _enrichWithNames(orders, loadSeller: true);
}

// NOVI KOD:
Future<List<OrderModel>> _fetchOrdersByBuyer(
  String buyerId, {
  int limit = _kPageSize,
  int offset = 0,
  String? statusFilter,
}) async {
  return ErrorHandlerService().executeWithRetry(
    'Fetch orders for buyer $buyerId (offset: $offset)',
    () async {
      var query = _client.from('orders').select().eq('buyer_id', buyerId);
      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }
      final list = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final orders = (list as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return _enrichWithNames(orders, loadSeller: true);
    },
    maxRetries: 2,
    shouldRetry: (error) => error.isNetworkError,
  );
}
*/

// ============================================================================
// TOOLS & DEBUGGING
// ============================================================================

/*
Kako debug-ovati error handling:

1. U main.dart, setup global error listener:
   
   void main() async {
     // ... init code ...
     
     ErrorHandlerService().addErrorListener((error) {
       print('🔴 ERROR: ${error.message}');
       print('   Type: ${error.type}');
       print('   Code: ${error.code}');
       print('   User message: ${error.getUserMessage()}');
     });
   }

2. U VS Code debug console, filtriraj po [MLEKO]:
   
   > Show output... → Dart
   Prikaži samo [MLEKO] poruke

3. Test network greške:
   
   DevTools → Network Throttling → Offline
   (onda radi neka akcija koja poziva API)

4. Test timeout:
   
   U Supabase → RLS Policies, makni select permisije
   (simulira dugo čekanje)

5. Simuliraj crash:
   
   throw Exception('Test crash');
   Trebalo bi da vidiš ErrorDialog sa detaljima
*/
