import 'package:flutter/material.dart';

/// Owns a [FocusNode] for the row a sheet should open on, and claims focus for
/// it once the sheet has built.
///
/// ListTile.autofocus is not enough on Web. It registers the right node -- a
/// single Tab lands on exactly the row autofocus named -- but it depends on the
/// modal route's FocusScope taking focus when the route is pushed, and that does
/// not happen in a browser. Verified in Chrome against this build: with the
/// Theme sheet fully open, document.activeElement was still the *toolbar
/// button* that opened it, outside the sheet's route. Arrows therefore traversed
/// the toolbar behind the barrier and Enter re-fired a toolbar button, which
/// reads to the user as the keyboard doing nothing at all. Requesting focus on a
/// real node after the frame does not wait for the scope to claim anything.
///
/// Widget tests cannot catch this: the test binding pushes focus into the route
/// scope, and the Theme sheet's test only ever runs with the default theme,
/// whose row is first in the list either way.
class SheetInitialFocus extends StatefulWidget {
  final Widget Function(FocusNode rowFocusNode) builder;

  const SheetInitialFocus({super.key, required this.builder});

  @override
  State<SheetInitialFocus> createState() => _SheetInitialFocusState();
}

class _SheetInitialFocusState extends State<SheetInitialFocus> {
  final FocusNode _rowFocusNode = FocusNode(debugLabel: 'sheet initial row');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rowFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _rowFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_rowFocusNode);
}
