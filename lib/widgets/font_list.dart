import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_settings.dart';

/// The scrolling list of fonts.
///
/// Stateful so it can reveal the active font when the sheet opens. Rows past
/// the viewport are built lazily, and a row that is never built can neither be
/// seen nor take keyboard focus, so a font near the end of the list would
/// otherwise be invisible and unreachable when its own picker opens.
class FontList extends StatefulWidget {
  final ScrollController scrollController;
  final String? selectedFamily;
  final ValueChanged<String?> onSelected;

  const FontList({
    super.key,
    required this.scrollController,
    required this.selectedFamily,
    required this.onSelected,
  });

  @override
  State<FontList> createState() => _FontListState();
}

class _FontListState extends State<FontList> {
  /// Enforced on the ListView below, so the offset arithmetic in
  /// [_revealSelection] is exact by construction rather than an assumption
  /// about how tall a ListTile happens to render.
  static const double _tileExtent = 56;

  static const List<String?> _options = [null, ...availableFonts];

  final FocusNode _selectedNode = FocusNode(debugLabel: 'selected font');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _revealSelection();
      // The jump above changes which rows exist, so the selected row is only
      // built on the frame after it. Requesting focus any earlier targets a node
      // with no context. See SheetInitialFocus for why autofocus is not enough.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) _selectedNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _selectedNode.dispose();
    super.dispose();
  }

  void _revealSelection() {
    final index = _options.indexOf(widget.selectedFamily);
    if (!mounted || index <= 0) return;
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    controller.jumpTo(
      (index * _tileExtent).clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemExtent: _tileExtent,
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final family = _options[index];
        final selected = family == widget.selectedFamily;
        return FontTile(
          label: family ?? 'Source Code Pro (Default)',
          style: GoogleFonts.getFont(family ?? 'Source Code Pro'),
          selected: selected,
          focusNode: selected ? _selectedNode : null,
          onTap: () => widget.onSelected(family),
        );
      },
    );
  }
}

class FontTile extends StatelessWidget {
  final String label;
  final TextStyle style;
  final bool selected;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const FontTile({
    super.key,
    required this.label,
    required this.style,
    required this.selected,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Opening on the active row lets arrow keys navigate from where the user
      // already is. The initial focus claim is explicit rather than autofocus --
      // see SheetInitialFocus.
      focusNode: focusNode,
      title: Text(label, style: style),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
