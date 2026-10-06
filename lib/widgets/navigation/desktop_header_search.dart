import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import 'desktop_top_utility_strip.dart';

/// Integrisano polje za pretragu na desktopu sa brzim biračem lokacije.
class DesktopHeaderSearch extends StatefulWidget {
  final bool isDark;
  final String? selectedRegion;
  final ValueChanged<String> onSearchSubmitted;

  const DesktopHeaderSearch({
    super.key,
    required this.isDark,
    required this.selectedRegion,
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final selectedRegion = widget.selectedRegion;

    return Container(
      height: 42,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B21) : const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _isSearchFocused
              ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
              : (isDark ? const Color(0xFF2C3E2F) : const Color(0xFFD6DFD6)),
          width: _isSearchFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: _isSearchFocused
                ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                : (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) => widget.onSearchSubmitted(val),
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : AmazonColors.darkNavy,
              ),
              decoration: InputDecoration(
                hintText: 'Pretraži sir, med, voće, traktore, oglase...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
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
              onPressed: () {
                _searchController.clear();
                widget.onSearchSubmitted('');
              },
            ),
          // Birač lokacije unutar pretrage
          InkWell(
            onTap: () => openLocationDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 13, color: isDark ? AmazonColors.lightGreen : AmazonColors.green),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      selectedRegion ?? 'Srbija',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AmazonColors.darkNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
