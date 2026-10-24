import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/conversation_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_back_button.dart';
import '../widgets/chat/conversation_list_tile.dart';
import '../widgets/chat/conversations_desktop_sidebar.dart';
import '../widgets/skeleton.dart';

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
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
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
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
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
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
    if (result == 'favorite') unawaited(_toggleFavorite(conv));
    if (result == 'hide') unawaited(_hideConversation(conv));
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
                    ? AppEmptyState(
                        icon: Icons.star_border,
                        title: 'Nema omiljenih',
                        subtitle:
                            'Pritisnite i zadržite razgovor da ga dodate u omiljene.',
                        ctaLabel: 'Prikaži sve razgovore',
                        ctaIcon: Icons.chat_bubble_outline,
                        onCtaPressed: () => _tabController.animateTo(0),
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
              return ConversationListTile(
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Poruke'),
          actions: const [AppHomeButton()],
        ),
        body: AppEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Vaše poruke',
          subtitle:
              'Prijavite se da biste mogli da komunicirate sa prodavcima.',
          ctaLabel: 'Prijavi se',
          onCtaPressed: () => context.go('/login'),
        ),
      );
    }

    _initStream(user.id);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final panelGap = Breakpoints.panelGap(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Poruke'),
        actions: const [
          AppHomeButton(),
        ],
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
                        child: ConversationsDesktopSidebar(
                          list: list,
                          selectedIndex: _tabController.index,
                          onSelectTab: (idx) =>
                              _tabController.animateTo(idx),
                          onRefresh: () => _refreshController.add(null),
                        ),
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
