import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A bottom sheet that collects one whole number in a range.
///
/// Returns the accepted value via [Navigator.pop], so the caller decides what
/// to persist and nothing is committed unless the user applies a valid entry.
/// Stateful so the field's controller and focus node are disposed with the
/// sheet rather than leaking on every open.
class NumericSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String errorMessage;
  final AppColors colors;

  const NumericSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.errorMessage,
    required this.colors,
  });

  @override
  State<NumericSheet> createState() => _NumericSheetState();
}

class _NumericSheetState extends State<NumericSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialValue}');
    _selectAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Selects the whole value so the next keystroke replaces it rather than
  /// appending to it.
  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _apply() {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.minValue || value > widget.maxValue) {
      // The sheet deliberately stays open: closing it would discard the value
      // the user has just been asked to correct. The message is inline rather
      // than a dialog so it matches the Font Size sheet and costs no keypress
      // to dismiss.
      setState(() => _error = widget.errorMessage);
      _focusNode.requestFocus();
      _selectAll();
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    // Scrollable for the same reason as FontSizeSheet: viewInsets.bottom
    // below lifts the sheet clear of the soft keyboard, and at a large
    // accessibility text scale the header, field and buttons together can
    // exceed what is left. Pairs with isScrollControlled: true at the call
    // site; without that this has no room to expand into.
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _apply(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: widget.hintText,
                errorText: _error,
                filled: true,
                fillColor: colors.buttonBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              overflowSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: _apply, child: const Text('Apply')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
