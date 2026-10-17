import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// Integrisano polje za pretragu na desktopu (Amazon / Allegro standard).
class DesktopHeaderSearch extends StatefulWidget {
  final bool isDark;
  final String? selectedRegion;
  final ValueChanged<String> onSearchSubmitted;

  const DesktopHeaderSearch({
    super.key,
    required this.isDark,
    this.selectedRegion,
    required this.onSearchSubmitted,
  });

  @override
  State<DesktopHeaderSearch> createState() => _DesktopHeaderSearchState();
}

class _DesktopHeaderSearchState extends State<DesktopHeaderSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearchSubmitted(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B281E) : Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: _isSearchFocused
                ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                : (isDark ? const Color(0xFF2C3E2F) : const Color(0xFFD0D7D0)),
            width: _isSearchFocused ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: _isSearchFocused ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: _isSearchFocused
                  ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                  : (isDark ? Colors.white60 : Colors.black45),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AmazonColors.darkNavy,
                ),
                decoration: InputDecoration(
                  hintText: 'Pretražite domaću hranu, sireve, med, voće, traktore, oglase...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.normal,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: isDark ? Colors.white54 : Colors.black45,
                tooltip: 'Obriši tekst',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  widget.onSearchSubmitted('');
                },
              ),
            // Amazon Signature Warm Amber Search Button sa desne strane
            Tooltip(
              message: 'Pretraži',
              child: InkWell(
                onTap: _submit,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Container(
                  width: 48,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AmazonColors.amberLight,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AmazonColors.darkNavy,
                    ),
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
