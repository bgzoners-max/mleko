import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mleko/services/services.dart';
import '../../providers/app_state.dart';

import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/home/seller_inbox_item.dart';
import '../../widgets/seller/conversation_inbox_card.dart';
import '../../widgets/seller/order_inbox_card.dart';
import '../../widgets/skeleton.dart';

/// Jedinstveni inbox za prodavca â€“ porudÅ¾bine i razgovori u jednoj listi
class SellerInboxScreen extends StatefulWidget {
  /// Samo razgovori (bez porudÅ¾bina bez razgovora) â€“ za tab Razgovori
  final bool showOnlyConversations;
  final bool showAppBar;

  const SellerInboxScreen(
      {super.key, this.showOnlyConversations = false, this.showAppBar = true});

  @override
  State<SellerInboxScreen> createState() => _SellerInboxScreenState();
}

class _SellerInboxScreenState extends State<SellerInboxScreen>
    with AutomaticKeepAliveClientMixin {
  final _refreshController = StreamController<void>.broadcast();
  final SellerInboxService _sellerInboxService = SellerInboxService();
  final ScrollController _scrollController = ScrollController();
  Stream<List<SellerInboxItem>>? _inboxStream;
  String? _inboxUserId;
  int _limit = 20;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<SellerInboxItem>? _lastItems;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && user.isSeller && _inboxUserId != user.id) {
      _inboxUserId = user.id;
      _initStream(user.id);
    }
  }

  void _initStream(String userId) {
    _inboxStream = _sellerInboxService.watchInbox(
      userId,
      refreshTrigger: _refreshController.stream,
    );
  }

  void _onScroll() {
    // Ako smo blizu dna liste (300px od kraja) i ima joÅ¡ podataka, uÄitaj sledeÄ‡u "stranu"
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_inboxUserId == null || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    setState(() {
      _limit += 20;
      _initStream(_inboxUserId!);
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _limit = 20;
      _hasMore = true;
    });
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AppState>().user;
    if (user == null || !user.isSeller) {
      _inboxStream = null;
      _inboxUserId = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: AppEmptyState(
          icon: Icons.store_mall_directory_outlined,
          title: 'Samo za prodavce.',
          subtitle: user == null
              ? 'Prijavite se i aktivirajte prodavca da biste koristili inbox.'
              : 'Ova sekcija je dostupna samo prodavcima.',
          ctaLabel: user == null ? 'Prijavi se' : null,
          ctaIcon: Icons.login,
          onCtaPressed: user == null ? () => context.go('/login') : null,
        ),
      );
    }

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Razgovori')) : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<SellerInboxItem>>(
              stream: _inboxStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return AppErrorRetry(
                    message: 'GreÅ¡ka pri uÄitavanju inbox-a.',
                    detail: snap.error?.toString(),
                    onRetry: () => _refreshController.add(null),
                  );
                }

                if (snap.hasData) {
                  _lastItems = snap.data;
                }

                if (snap.connectionState != ConnectionState.waiting) {
                  _loadingMore = false;
                }

                if (snap.connectionState == ConnectionState.waiting &&
                    (_lastItems == null || _lastItems!.isEmpty)) {
                  return const OrderListSkeleton();
                }

                var list = snap.data ?? _lastItems ?? [];
                if (widget.showOnlyConversations) {
                  list = list
                      .where((i) => i.type == SellerInboxItemType.conversation)
                      .toList();
                }

                // AÅ¾uriramo _hasMore van build faze u stream listeneru ili ovde preko post frame callback-a
                if (list.length < _limit && _hasMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _hasMore = false);
                  });
                }

                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: AppEmptyState(
                          icon: Icons.chat_outlined,
                          title: widget.showOnlyConversations
                              ? 'Nema razgovora'
                              : 'Nema upita ni poruka',
                          subtitle: widget.showOnlyConversations
                              ? 'Kada kupci poÅ¡alju poruku, pojaviÄ‡e se ovde.'
                              : 'Upiti i poruke od kupaca Ä‡e se pojaviti ovde kada poÄnu da naruÄuju.',
                          ctaLabel: 'Pregledaj proizvode',
                          ctaIcon: Icons.storefront_outlined,
                          onCtaPressed: () => context.go('/'),
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == list.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = list[i];
                      return item.type == SellerInboxItemType.order
                          ? OrderInboxCard(
                              item: item,
                              user: user,
                              onRefresh: () => _refreshController.add(null),
                            )
                          : ConversationInboxCard(
                              item: item,
                              onRefresh: () => _refreshController.add(null),
                            );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
