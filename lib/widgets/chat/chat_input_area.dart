import 'package:flutter/material.dart';

/// Područje za unos poruke u direktnom chatu sa vidljivom proširivom (expandable) sekcijom ispod.
///
/// 1. Polje za unos je gore i potpuno rasterećeno (nema ničega što smeta iznad polja).
/// 2. Ispod polja za unos nalazi se sekcija za gotove šablone koja je jasno vidljiva.
/// 3. Čim korisnik klikne na polje za tekst ili počne da kuca, sekcija se automatski
///    skuplja (collapse) da ne zauzima ekran tastaturi.
/// 4. Klik na šablon ubacuje tekst u polje za dopunu/izmenu, a strelica šalje odmah.
class ChatInputArea extends StatefulWidget {
  final TextEditingController messageController;
  final bool isUploadingImage;
  final bool isSending;
  final VoidCallback onPickImage;
  final void Function([String?]) onSend;
  final List<String> quickReplies;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.isUploadingImage,
    required this.isSending,
    required this.onPickImage,
    required this.onSend,
    required this.quickReplies,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  late final FocusNode _focusNode;
  // Otvoreno inicijalno kako bi korisnik odmah video proširenu sekciju ispod
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.messageController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageController != widget.messageController) {
      oldWidget.messageController.removeListener(_onTextChanged);
      widget.messageController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.messageController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    // Čim korisnik fokusira polje za kucanje, automatski sklopi šablone da ne smetaju
    if (_focusNode.hasFocus && _isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  void _onTextChanged() {
    // Ako korisnik krene da kuca tekst dok su šabloni prošireni, automatski ih sklopi
    if (widget.messageController.text.isNotEmpty && _isExpanded) {
      setState(() => _isExpanded = false);
    }
  }

  void _toggleExpanded() {
    if (!_isExpanded) {
      // Spusti tastaturu da bi se sekcija sa šablonima lepo prikazala
      _focusNode.unfocus();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _insertTemplate(String reply) {
    final current = widget.messageController.text;
    if (current.trim().isEmpty) {
      widget.messageController.text = reply;
    } else {
      widget.messageController.text = '$current $reply';
    }
    // Postavi kursor na kraj unetog teksta i vrati fokus na polje
    widget.messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.messageController.text.length),
    );
    setState(() => _isExpanded = false);
    _focusNode.requestFocus();
  }

  void _sendTemplate(String reply) {
    setState(() => _isExpanded = false);
    widget.onSend(reply);
  }

  void _showBottomSheetTemplates(BuildContext context) {
    _focusNode.unfocus();
    setState(() => _isExpanded = false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Brzi šabloni za odgovor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Dodirnite tekst da ga ubacite u polje ili strelicu da pošaljete odmah.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.quickReplies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final reply = widget.quickReplies[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        title: Text(reply, style: theme.textTheme.bodyMedium),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded),
                          tooltip: 'Pošalji odmah',
                          onPressed: widget.isSending
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  widget.onSend(reply);
                                },
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _insertTemplate(reply);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuickReplies = widget.quickReplies.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Glavni red za unos poruke: [Slika] [Tekst polje] [Dugme Pošalji]
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Unesite poruku...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      prefixIcon: IconButton(
                        icon: widget.isUploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image_outlined),
                        onPressed: widget.onPickImage,
                        tooltip: 'Priloži sliku',
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => widget.onSend(),
                  ),
                ),
                if (hasQuickReplies) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: _isExpanded ? 'Sakrij šablone' : 'Brzi šabloni',
                    style: IconButton.styleFrom(
                      backgroundColor: _isExpanded
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      foregroundColor: _isExpanded
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.primary,
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: Icon(
                      _isExpanded
                          ? Icons.quickreply_rounded
                          : Icons.quickreply_outlined,
                      size: 22,
                    ),
                    onPressed: _toggleExpanded,
                  ),
                ],
                const SizedBox(width: 4),
                IconButton.filled(
                  onPressed: widget.isSending ? null : () => widget.onSend(),
                  tooltip: 'Pošalji',
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),

            // 2. Jasno vidljiva proširiva sekcija ISPOD gde se nalaze gotovi šabloni
            if (hasQuickReplies) ...[
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Traka / zaglavlje sekcije ispod polja za unos
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _toggleExpanded,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Gotovi šabloni',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${widget.quickReplies.length})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isExpanded
                                    ? '• dodirni za unos u polje'
                                    : '• klikni za prikaz',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Tooltip(
                              message: 'Prikaži kao prozor',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showBottomSheetTemplates(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Proširivi sadržaj sa čipovima šablona
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: _isExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Divider(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.quickReplies.map((reply) {
                                      return _QuickReplyChip(
                                        text: reply,
                                        isSending: widget.isSending,
                                        onTapText: () => _insertTemplate(reply),
                                        onTapSend: () => _sendTemplate(reply),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String text;
  final bool isSending;
  final VoidCallback onTapText;
  final VoidCallback onTapSend;

  const _QuickReplyChip({
    required this.text,
    required this.isSending,
    required this.onTapText,
    required this.onTapSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              onTap: onTapText,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 16,
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              onTap: isSending ? null : onTapSend,
              child: Tooltip(
                message: 'Pošalji odmah',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
