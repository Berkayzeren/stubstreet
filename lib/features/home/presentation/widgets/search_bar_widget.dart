// lib/features/home/presentation/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final padding = ResponsivePadding.responsive(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    final borderRadius = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);

    return Container(
      padding: padding,
      child: Semantics(
        textField: true,
        label: 'Search for tickets, events, or venues',
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Bilet, etkinlik veya mekan ara...',
            prefixIcon: Semantics(
              label: 'Search icon',
              child: const Icon(Icons.search),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? Semantics(
                    button: true,
                    label: 'Clear search',
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                      },
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            contentPadding: EdgeInsets.all(
              isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0),
            ),
          ),
          style: TextStyle(
            fontSize: isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0),
          ),
          onChanged: (value) {
            setState(() {}); // Suffix icon'u güncellemek için
            widget.onSearch(value);
          },
          onSubmitted: widget.onSearch,
        ),
      ),
    );
  }
}
