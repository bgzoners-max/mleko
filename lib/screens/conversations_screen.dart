import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/conversation_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_network_image.dart';
import '../widgets/skeleton.dart';

String _formatConvTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
  if (diff.inDays == 1) return 'juče';
  if (diff.inDays < 7) return DateFormat('EEE', 'sr').format(dt);
  if (dt.year == now.year) return DateFormat('d. MMM', 'sr').format(dt);
  return DateFormat('d.M.yy', 'sr').format(dt);
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final _refreshController = StreamController<void>.broadcast();

  Stream<List<ConversationModel>>? _conversationsStream;
  String? _streamUserId;

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _refreshController.close();
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() {});
  }

  void _initStream(String userId) {
    if (_streamUserId == userId) return;
    _streamUserId = userId;
    _conversationsStream = context.read<ChatService>()
        .watchConversations(userId, refreshTrigger: _refreshController.stream);
  }

  Future<void> _toggleFavorite(ConversationModel conv) async {
    final chatService = context.read<ChatService>();
    try {
      await chatService.setConversationUserPrefs(
        conv.id,
        isFavorite: !conv.isFavorite,
      );
      _refreshController.add(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hideConversation(ConversationModel conv) async {
    final chatService = context.read<ChatService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sakrij razgovor'),
        content: const Text(
            'Razgovor će biti sakriven iz liste. Možete ga ponovo pronaći u podešavanjima.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Odustani')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sakrij'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await chatService.setConversationUserPrefs(conv.id, hidden: true);
      _refreshController.add(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showConversationMenu(BuildContext context, ConversationModel conv,
      {Offset? tapPosition}) {
    if (tapPosition != null) {
      _showDesktopMenu(context, conv, tapPosition);
    } else {
      _showMobileSheet(context, conv);
    }
  }

  Future<void> _showDesktopMenu(
      BuildContext context, ConversationModel conv, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final rel = RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 1, 1),
      Offset.zero & overlay.size,
    );
    final result = await showMenu<String>(
      context: context,
      position: rel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          value: 'favorite',
          child: Row(
            children: [
              Icon(
                conv.isFavorite ? Icons.star : Icons.star_border,
                size: 18,
                color: conv.isFavorite ? Colors.amber : null,
              ),
              const SizedBox(width: 10),
              Text(
                  conv.isFavorite ? 'Ukloni iz omiljenih' : 'Dodaj u omiljene'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'hide',
          child: Row(
            children: [
              Icon(Icons.visibility_off_outlined, size: 18),
              SizedBox(width: 10),
              Text('Sakrij razgovor'),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (result == 'favorite') _toggleFavorite(conv);
    if (result == 'hide') _hideConversation(conv);
  }

  void _showMobileSheet(BuildContext context, ConversationModel conv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conv.isFavorite ? Icons.star : Icons.star_border,
                color: conv.isFavorite ? Colors.amber : null,
              ),
              title: Text(
                  conv.isFavorite ? 'Ukloni iz omiljenih' : 'Dodaj u omiljene'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(conv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Sakrij razgovor'),
              onTap: () {
                Navigator.pop(context);
                _hideConversation(conv);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<ConversationModel> list,
    bool favoritesOnly, {
    bool constrainContent = true,
  }) {
    final filtered =
        favoritesOnly ? list.where((c) => c.isFavorite).toList() : list;

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _refreshController.add(null),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: favoritesOnly
                    ? const AppEmptyState(
                        icon: Icons.star_border,
                        title: 'Nema omiljenih',
                        subtitle:
                            'Pritisnite i zadržite razgovor da ga dodate u omiljene.',
                      )
                    : AppEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Nema poruka',
                        subtitle:
                            'Poruke sa prodavcima će se pojaviti ovde kada im pošaljete upit.',
                        ctaLabel: 'Pretraži proizvode',
                        ctaIcon: Icons.search,
                        onCtaPressed: () => context.go('/'),
                      ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshController.add(null),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constrainContent
                ? Breakpoints.maxContentWidth(context)
                : double.infinity,
          ),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(Breakpoints.horizontalPadding(context)),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final conv = filtered[i];
              return _ConversationTile(
                conv: conv,
                onTap: () => context.push('/chat/${conv.id}'),
                onLongPress: () => _showConversationMenu(context, conv),
                onSecondaryTap: (pos) =>
                    _showConversationMenu(context, conv, tapPosition: pos),
                onToggleFavorite: () => _toggleFavorite(conv),
                onHide: () => _hideConversation(conv),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    List<ConversationModel> list,
  ) {
    final favoritesCount = list.where((c) => c.isFavorite).length;
    final unreadCount = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
    final cardPadding = Breakpoints.cardPadding(context);
    final selectedIndex = _tabController.index;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Poruke',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Brz pregled razgovora i nepročitanih poruka.',
                    style: Breakpoints.supportingTextStyle(
                      context,
                      Theme.of(context).textTheme.bodyMedium,
                      phone: 13,
                      largeTabletValue: 14,
                      desktop: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.chat_bubble_outline,
                        label: 'Ukupno',
                        value: list.length.toString(),
                      ),
                      _StatChip(
                        icon: Icons.star_border,
                        label: 'Omiljeni',
                        value: favoritesCount.toString(),
                      ),
                      _StatChip(
                        icon: Icons.mark_chat_unread_outlined,
                        label: 'Nepročitano',
                        value: unreadCount.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _refreshController.add(null),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Osveži razgovore'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: Breakpoints.panelGap(context)),
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Prikaz',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SidebarNavTile(
                    icon: Icons.chat_outlined,
                    label: 'Svi razgovori',
                    selected: selectedIndex == 0,
                    onTap: () => _tabController.animateTo(0),
                  ),
                  const SizedBox(height: 8),
                  _SidebarNavTile(
                    icon: Icons.star_border,
                    label: 'Omiljeni',
                    selected: selectedIndex == 1,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Poruke')),
        body: const Center(child: Text('Prijavite se da vidite poruke.')),
      );
    }

    _initStream(user.id);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final panelGap = Breakpoints.panelGap(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poruke'),
        bottom: isTwoPaneLayout
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Svi'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16),
                        SizedBox(width: 4),
                        Text('Omiljeni'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _conversationsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju poruka.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const ConversationListSkeleton();
          }
          final list = (snap.data ?? []).where((c) => !c.hidden).toList();

          if (isTwoPaneLayout) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Breakpoints.dataContentWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: Breakpoints.desktopSidebarWidth(context),
                        child: _buildDesktopSidebar(context, list),
                      ),
                      SizedBox(width: panelGap),
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  Breakpoints.cardPadding(context),
                                  Breakpoints.cardPadding(context),
                                  Breakpoints.cardPadding(context),
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _tabController.index == 1
                                            ? 'Omiljeni razgovori'
                                            : 'Svi razgovori',
                                        style: Breakpoints.sectionTitleStyle(
                                          context,
                                          Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          '${_tabController.index == 1 ? list.where((c) => c.isFavorite).length : list.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: _buildList(
                                  list,
                                  _tabController.index == 1,
                                  constrainContent: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(list, false),
              _buildList(list, true),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: selected ? colorScheme.primary : null),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text('$label: $value'),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation tile with hover actions for desktop ─────────────────────────

class _ConversationTile extends StatefulWidget {
  final ConversationModel conv;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(Offset) onSecondaryTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onHide;

  const _ConversationTile({
    required this.conv,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
    required this.onToggleFavorite,
    required this.onHide,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final conv = widget.conv;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onSecondaryTapUp: (d) => widget.onSecondaryTap(d.globalPosition),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar
                  conv.otherPartyImageUrl != null &&
                          conv.otherPartyImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: AppNetworkImage.profileSmall(
                            imageUrl: conv.otherPartyImageUrl!,
                            width: 44,
                            height: 44,
                          ),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade300,
                          child:
                              Icon(Icons.person, color: Colors.grey.shade600),
                        ),
                  const SizedBox(width: 12),
                  // Tekst
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (conv.isFavorite)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.star,
                                    size: 14, color: Colors.amber.shade700),
                              ),
                            Expanded(
                              child: Text(
                                conv.otherPartyName ?? 'Korisnik',
                                style: TextStyle(
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          conv.lastMessageBody ?? 'Nema poruka',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conv.unreadCount > 0
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hover akcije (desktop) ili vreme+badge (uvek)
                  if (_hovered)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: conv.isFavorite
                              ? 'Ukloni iz omiljenih'
                              : 'Dodaj u omiljene',
                          icon: Icon(
                            conv.isFavorite ? Icons.star : Icons.star_border,
                            color: conv.isFavorite ? Colors.amber : null,
                          ),
                          onPressed: widget.onToggleFavorite,
                        ),
                        IconButton(
                          tooltip: 'Sakrij razgovor',
                          icon: const Icon(Icons.visibility_off_outlined),
                          onPressed: widget.onHide,
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatConvTime(conv.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: conv.unreadCount > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (conv.unreadCount > 0)
                          Badge(
                            label: Text('${conv.unreadCount}'),
                            child: const SizedBox(width: 8),
                          )
                        else
                          const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
