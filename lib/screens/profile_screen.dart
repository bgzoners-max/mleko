import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'favorite_sellers_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'categories_screen.dart';
import 'seller/becoming_seller_screen.dart';
import 'buyer/buyer_reviews_hub_screen.dart';
import 'seller/seller_reviews_screen.dart';

const _kSellerTags = [
  'Bio sertifikat',
  'Direktna dostava',
  'Preuzimanje na licu mesta',
  'Plaćanje gotovinom',
  'Plaćanje karticom',
  'PDV obveznik',
  'Organski uzgoj',
  'Sezonski',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _panelNavKey = GlobalKey<NavigatorState>();
  String? _activeSection;

  void _showInPanel(String section, Widget screen) {
    setState(() => _activeSection = section);
    _panelNavKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Niste prijavljeni.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Prijavi se'),
              ),
            ],
          ),
        ),
      );
    }
    final isWide = Breakpoints.useTwoPaneLayout(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child:
              isWide ? _buildWide(context, user) : _buildNarrow(context, user),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (user.isSeller) ...[
                    _SellerProfilePhotoSection(user: user),
                    const SizedBox(height: 6),
                    _SellerGallerySection(user: user),
                    const SizedBox(height: 6),
                  ],
                  _ProfileDataCard(user: user),
                  const SizedBox(height: 6),
                  if (user.isSeller) ...[
                    _MiniStoreCard(user: user),
                    const SizedBox(height: 6),
                  ],
                  Card(
                    child: Column(
                      children: _buildNavItems(context, user, isWide: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Flexible(
          flex: 7,
          child: HeroControllerScope.none(
            child: Navigator(
              key: _panelNavKey,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const _PanelPlaceholder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context, UserModel user) {
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final profileCards = [
      if (user.isSeller) _SellerProfilePhotoSection(user: user),
      if (user.isSeller) _SellerGallerySection(user: user),
      _ProfileDataCard(user: user),
    ];
    return ListView(
      padding: EdgeInsets.all(isSmallTablet ? 12 : 8),
      children: [
        ...profileCards,
        SizedBox(height: isSmallTablet ? 12 : 8),
        if (user.isSeller) ...[
          _MiniStoreCard(user: user),
          SizedBox(height: isSmallTablet ? 8 : 4),
        ],
        ..._buildNavItems(context, user, isWide: false),
      ],
    );
  }

  List<Widget> _buildNavItems(BuildContext context, UserModel user,
      {required bool isWide}) {
    void push(String route) => context.push(route);
    void openPanel(String section, Widget screen) =>
        _showInPanel(section, screen);
    bool isActive(String section) => isWide && _activeSection == section;

    return [
      ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Podešavanja'),
        subtitle: const Text('Obaveštenja, prodavac, podrška'),
        selected: isActive('settings'),
        onTap: () => isWide
            ? openPanel('settings', const SettingsScreen())
            : push('/settings'),
      ),
      if (!user.isGuest)
        ListTile(
          leading: const Icon(Icons.rate_review_outlined),
          title: const Text('Recenzije'),
          subtitle: Text(
            user.isSeller
                ? 'Ocene kupaca i tvoji odgovori'
                : 'Primljene i ostavljene ocene (međusobno ocenjivanje)',
          ),
          selected: isActive('reviews'),
          onTap: () {
            if (isWide) {
              openPanel(
                'reviews',
                user.isSeller
                    ? SellerReviewsScreen(sellerId: user.id)
                    : BuyerReviewsHubScreen(buyerId: user.id),
              );
            } else {
              if (user.isSeller) {
                push('/seller/${user.id}/reviews');
              } else {
                push('/buyer/${user.id}/reviews');
              }
            }
          },
        ),
      const Divider(height: 1),
      if (user.isSeller) ...[
        if (!user.isGuest)
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Poruke'),
            selected: isActive('messages'),
            onTap: () => isWide
                ? openPanel('messages', const ConversationsScreen())
                : push('/conversations'),
          ),
        if (!user.isGuest)
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Obaveštenja'),
            selected: isActive('notifications'),
            onTap: () => isWide
                ? openPanel('notifications', const NotificationsScreen())
                : push('/notifications'),
          ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Lokacija za mapu'),
          subtitle: Text(user.lat != null && user.lng != null
              ? 'Lokacija postavljena'
              : 'Odaberi na mapi da te kupci vide'),
          onTap: () => push('/seller-settings'),
        ),
      ] else ...[
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Omiljeni proizvodi'),
          selected: isActive('favorites'),
          onTap: () => isWide
              ? openPanel('favorites', const FavoritesScreen())
              : push('/favorites'),
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: const Text('Pratim prodavce'),
          selected: isActive('favorite-sellers'),
          onTap: () => isWide
              ? openPanel('favorite-sellers', const FavoriteSellersScreen())
              : push('/favorite-sellers'),
        ),
        if (!user.isGuest)
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Obaveštenja'),
            selected: isActive('notifications'),
            onTap: () => isWide
                ? openPanel('notifications', const NotificationsScreen())
                : push('/notifications'),
          ),
      ],
      if (!user.isGuest && !user.isSeller)
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Poruke'),
          selected: isActive('messages'),
          onTap: () => isWide
              ? openPanel('messages', const ConversationsScreen())
              : push('/conversations'),
        ),
      ListTile(
        leading: const Icon(Icons.map),
        title: const Text('Prodavci na mapi'),
        onTap: () => push('/sellers-map'),
      ),
      ListTile(
        leading: const Icon(Icons.category),
        title: const Text('Kategorije'),
        selected: isActive('categories'),
        onTap: () => isWide
            ? openPanel('categories', const CategoriesScreen())
            : push('/categories'),
      ),
      if (!user.isSeller && !user.isGuest) ...[
        ListTile(
          leading: const Icon(Icons.store),
          title: const Text('Postani prodavac'),
          selected: isActive('becoming-seller'),
          onTap: () => isWide
              ? openPanel('becoming-seller', const BecomingSellerScreen())
              : push('/becoming-seller'),
        ),
      ] else if (user.isGuest) ...[
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Da bi postao prodavac, registruj nalog'),
          subtitle: const Text('Gost može samo da pregleda proizvode.'),
          onTap: () => push('/register'),
        ),
      ],
      ListTile(
        leading: const Icon(Icons.support),
        title: const Text('Podrška / prijava problema'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/support'),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Odjavi se'),
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Odjavi se?'),
              content:
                  const Text('Da li ste sigurni da želite da se odjavite?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Odjavi se'),
                ),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await context.read<AppState>().authService.signOut();
            if (context.mounted) context.go('/login');
          }
        },
      ),
    ];
  }
}

class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Odaberite stavku iz menija',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _MiniStoreCard extends StatelessWidget {
  final UserModel user;
  const _MiniStoreCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.go(user.isSeller ? '/search?view=products' : '/search'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mini prodavnica',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.farmName ?? 'Moji proizvodi i porudžbine',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerProfilePhotoSection extends StatefulWidget {
  final UserModel user;

  const _SellerProfilePhotoSection({required this.user});

  @override
  State<_SellerProfilePhotoSection> createState() =>
      _SellerProfilePhotoSectionState();
}

class _SellerProfilePhotoSectionState
    extends State<_SellerProfilePhotoSection> {
  bool _loading = false;
  late final Future<int> _followersFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture =
        FavoriteSellersService().getFollowersCount(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _followersFuture,
      builder: (context, snap) {
        final followersCount = snap.data ?? 0;
        return _SellerProfilePhotoContent(
            user: widget.user,
            followersCount: followersCount,
            loading: _loading,
            onPickAndUpload: _pickAndUpload);
      },
    );
  }

  Future<void> _pickAndUpload() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final url =
          await StorageService().uploadProfileImage(widget.user.id, bytes);
      await usersService.updateProfileImage(widget.user.id, url);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Profilna slika ažurirana.')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SellerProfilePhotoContent extends StatelessWidget {
  final UserModel user;
  final int followersCount;
  final bool loading;
  final Future<void> Function() onPickAndUpload;

  const _SellerProfilePhotoContent({
    required this.user,
    required this.followersCount,
    required this.loading,
    required this.onPickAndUpload,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user ?? user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: loading ? null : onPickAndUpload,
                  behavior: HitTestBehavior.opaque,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: currentUser.profileImageUrl != null
                        ? NetworkImage(currentUser.profileImageUrl!)
                        : null,
                    child: loading
                        ? const CircularProgressIndicator()
                        : currentUser.profileImageUrl == null
                            ? Icon(Icons.add_a_photo,
                                size: 32, color: Colors.grey.shade600)
                            : null,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: loading ? null : onPickAndUpload,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentUser.farmName ?? 'Gazdinstvo',
                      style: Theme.of(context).textTheme.titleMedium),
                  if (followersCount > 0) ...[
                    const SizedBox(height: 2),
                    Text('$followersCount pratilaca',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    loading
                        ? 'Učitavanje…'
                        : 'Dodirni da promeniš profilnu sliku',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerGallerySection extends StatefulWidget {
  final UserModel user;

  const _SellerGallerySection({required this.user});

  @override
  State<_SellerGallerySection> createState() => _SellerGallerySectionState();
}

// ─── Podaci + dugme za izmenu ─────────────────────────────────────────────────

class _ProfileDataCard extends StatelessWidget {
  final UserModel user;
  const _ProfileDataCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Moji podaci',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!user.isGuest)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Uredi'),
                    onPressed: () => _showEditSheet(context, user),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            if (user.createdAt != null) ...[
              Text(
                'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(user.createdAt!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 2),
            ],
            if (user.displayName != null)
              _DataRow(label: 'Ime', value: user.displayName!),
            if (user.phone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                              text: 'Telefon: ',
                              style: TextStyle(color: Colors.grey.shade600)),
                          TextSpan(text: user.phone!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: user.phonePublic
                          ? 'Vidljivo svima'
                          : 'Vidljivo samo tebi',
                      child: Icon(
                        user.phonePublic
                            ? Icons.lock_open_outlined
                            : Icons.lock_outline,
                        size: 13,
                        color: user.phonePublic
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            if (user.city != null) _DataRow(label: 'Grad', value: user.city!),
            if (user.postalCode != null) _DataRow(label: 'Poštanski broj', value: user.postalCode!),
            if (user.address != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                              text: 'Adresa: ',
                              style: TextStyle(color: Colors.grey.shade600)),
                          TextSpan(text: user.address!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Vidljivo samo tebi',
                      child: Icon(Icons.lock_outline,
                          size: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            if (user.email != null && !user.isGuest)
              _DataRow(label: 'Email', value: user.email!),
            if (user.isSeller && user.farmName != null)
              _DataRow(label: 'Gazdinstvo', value: user.farmName!),
            if (user.isSeller && user.sellerTags.isNotEmpty) ...[
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: user.sellerTags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(color: Colors.grey.shade600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ─── Edit profil bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _farmNameCtrl;
  late List<String> _selectedTags;
  late bool _phonePublic;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.displayName ?? '');
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _cityCtrl = TextEditingController(text: u.city ?? '');
    _postalCodeCtrl = TextEditingController(text: u.postalCode ?? '');
    _addressCtrl = TextEditingController(text: u.address ?? '');
    _farmNameCtrl = TextEditingController(text: u.farmName ?? '');
    _selectedTags = List.from(u.sellerTags);
    _phonePublic = u.phonePublic;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _addressCtrl.dispose();
    _farmNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = widget.user;
    setState(() => _saving = true);
    try {
      await usersService.upsertProfile(
        user.id,
        displayName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        postalCode:
            _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
        location:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phonePublic: _phonePublic,
        farmName: user.isSeller && _farmNameCtrl.text.trim().isNotEmpty
            ? _farmNameCtrl.text.trim()
            : null,
      );
      if (user.isSeller) {
        await usersService.updateSellerTags(user.id, _selectedTags);
      }
      await appState.refreshUser();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil sačuvan.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = widget.user.isSeller;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Uredi profil',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Zatvori',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ime i prezime', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                    labelText: 'Telefon', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return null;
                  final digits = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                  if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                    return 'Unesite ispravan broj telefona';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                value: _phonePublic,
                onChanged: (v) => setState(() => _phonePublic = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _phonePublic ? Icons.lock_open_outlined : Icons.lock_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _phonePublic ? 'Telefon vidljiv svima' : 'Telefon privatan',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'Grad', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return null;
                  if (val.length < 2) {
                    return 'Grad mora imati najmanje 2 karaktera';
                  }
                  if (RegExp(r'^\d+$').hasMatch(val)) {
                    return 'Unesite ispravan naziv grada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _postalCodeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Poštanski broj', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Adresa (ulica i broj)',
                  border: const OutlineInputBorder(),
                  helperText: 'Vidljiva samo tebi i prodavcu pri narudžbini',
                  helperStyle: TextStyle(color: Colors.grey.shade600),
                  suffixIcon: Tooltip(
                    message: 'Adresa nije javno vidljiva',
                    child: Icon(Icons.lock_outline,
                        size: 18, color: Colors.grey.shade500),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (isSeller) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _farmNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Naziv gazdinstva',
                      border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oznake gazdinstva',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSellerTags
                      .map((tag) => FilterChip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 13)),
                            selected: _selectedTags.contains(tag),
                            onSelected: (v) => setState(() {
                              if (v) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            }),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sačuvaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerGallerySectionState extends State<_SellerGallerySection> {
  bool _loading = false;
  late List<String> _galleryUrls;

  @override
  void initState() {
    super.initState();
    _galleryUrls = List.from(widget.user.farmGalleryUrls);
  }

  Future<void> _addPhoto() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final xFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final user = appState.user;
    if (!mounted || user == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final url = await StorageService()
          .uploadFarmGalleryImage(user.id, bytes, _galleryUrls.length);
      final newUrls = [..._galleryUrls, url];
      if (mounted) setState(() => _galleryUrls = newUrls);
      await usersService.updateFarmGallery(user.id, newUrls);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Slika dodata.')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = appState.user;
    if (user == null) return;
    final removed = _galleryUrls[index];
    final updated = List<String>.from(_galleryUrls)..removeAt(index);
    setState(() {
      _galleryUrls = updated;
      _loading = true;
    });
    try {
      await usersService.updateFarmGallery(user.id, updated);
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slika uklonjena.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _galleryUrls = List.from(_galleryUrls)..insert(index, removed));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user ?? widget.user;
    final urls = currentUser.farmGalleryUrls;
    final displayUrls = _galleryUrls.isNotEmpty ? _galleryUrls : urls;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Galerija farme',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Fotografije farme, stoke ili proizvodnje.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayUrls.asMap().entries.map((e) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: e.value,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            tooltip: 'Ukloni fotografiju',
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                            onPressed:
                                _loading ? null : () => _removePhoto(e.key),
                          ),
                        ),
                      ],
                    )),
                if (displayUrls.length < 10)
                  GestureDetector(
                    onTap: _loading ? null : _addPhoto,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
