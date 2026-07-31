import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

/// The Font Size sheet: a numeric field and a slider that both edit the same
/// value live, kept in sync with each other.
///
/// The field is autofocused with its value preselected, so the sheet is
/// typeable the instant it opens -- no button, no second sheet to reach a
/// keyboard. Field precedes the slider in the widget tree, so a single Tab
/// from the field reaches the slider.
class FontSizeSheet extends StatefulWidget {
  final AppSettings settings;
  final AppColors colors;

  const FontSizeSheet({super.key, required this.settings, required this.colors});

  @override
  State<FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<FontSizeSheet> {
  late double _size;
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _error;

  /// One Enter can arrive twice -- once as a raw key event through the
  /// sheet-level binding, once as a platform text input action through
  /// onSubmitted. See framework_assumptions_test.dart. Without this the second
  /// pop would dismiss whatever route is behind the sheet.
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _size = widget.settings.fontSize;
    _controller = TextEditingController(text: '${_size.round()}');
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

  // Applies a valid value immediately, matching the slider. An invalid or
  // incomplete value (e.g. "" while backspacing) is left un-applied and
  // silent -- flashing an error on every keystroke would fight the user
  // typing a number one digit at a time.
  void _onFieldChanged(String text) {
    final value = int.tryParse(text);
    if (value != null && value >= minFontSize && value <= maxFontSize) {
      setState(() {
        _error = null;
        _size = value.toDouble();
      });
      widget.settings.setFontSize(_size);
    } else if (_error != null) {
      setState(() => _error = null);
    }
  }

  /// Commits the sheet. Reachable from Apply, from the field's own Enter, and
  /// from the sheet-level Enter binding (which is how the slider commits).
  void _apply() {
    if (_closing) return;
    final value = int.tryParse(_controller.text);
    if (value == null || value < minFontSize || value > maxFontSize) {
      setState(() => _error = 'Enter a size between 6 and 999 pt');
      _focusNode.requestFocus();
      _selectAll();
      return;
    }
    // The value was already applied live by _onFieldChanged or _onSliderChanged.
    _closing = true;
    Navigator.pop(context, true);
  }

  void _onSliderChanged(double value) {
    final rounded = value.roundToDouble();
    setState(() {
      _error = null;
      _size = rounded;
      _controller.text = '${rounded.round()}';
      _selectAll();
    });
    widget.settings.setFontSize(rounded);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return CallbackShortcuts(
      // The slider owns focus after a drag and ignores Enter, so without a
      // sheet-level binding there is no way to commit from the keyboard once
      // you have touched it.
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _apply,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _apply,
      },
      // Scrollable because this sheet is the tallest of the five: with the
      // keyboard up on a short screen, the field, slider, scale labels and
      // buttons together can exceed what is left. Scrolling degrades better
      // than clipping the Apply button off the bottom.
      child: SingleChildScrollView(
      child: Padding(
      // viewInsets.bottom lifts the sheet clear of the soft keyboard. The
      // modal bottom sheet route does not do this for us -- it only clips to
      // its layout box -- so a sheet with a focused field has to pad itself,
      // exactly as NumericSheet does. Pairs with isScrollControlled: true at
      // the call site; without that this padding has no room to expand into.
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
                  'Font Size',
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
            onChanged: _onFieldChanged,
            onSubmitted: (_) => _apply(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
            decoration: InputDecoration(
              suffixText: 'pt',
              errorText: _error,
              filled: true,
              fillColor: colors.buttonBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _size.clamp(6, 144),
            min: 6,
            max: 144,
            divisions: 138,
            label: '${_size.round()}pt',
            onChanged: _onSliderChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('6pt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ),
              Flexible(
                child: Text(
                  '144pt',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
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
      ),
    );
  }
}
