import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_truncation.dart';


/// Curated list of 20 Google Fonts, sorted alphabetically.
const List<String> availableFonts = [
  'Courier Prime',
  'Crimson Text',
  'EB Garamond',
  'Fira Code',
  'IBM Plex Mono',
  'Inconsolata',
  'Inter',
  'JetBrains Mono',
  'Karla',
  'Lato',
  'Libre Baskerville',
  'Lora',
  'Merriweather',
  'Nunito',
  'Open Sans',
  'Playfair Display',
  'PT Serif',
  'Raleway',
  'Source Code Pro',
  'Work Sans',
];

class MainScreen extends StatefulWidget {
  final PreferencesService prefsService;

  const MainScreen({super.key, required this.prefsService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  final ValueNotifier<int> _charCount = ValueNotifier<int>(0);
  bool _isEnforcing = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() => _version = info.version);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _charCount.dispose();
    super.dispose();
  }

  void _onTextChanged(String text, AppSettings settings) {
    if (_isEnforcing) return;

    if (text.runes.length > settings.maxChars) {
      _isEnforcing = true;
      final trimmed = truncateRollingText(text, settings.maxChars);
      _controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      _isEnforcing = false;
    }
    _charCount.value = _controller.text.runes.length;
  }

  TextStyle _textStyle(AppSettings settings) {
    final base = TextStyle(fontSize: settings.fontSize);
    if (settings.fontFamily == null) {
      return GoogleFonts.getFont('Source Code Pro', textStyle: base);
    }
    return GoogleFonts.getFont(settings.fontFamily!, textStyle: base);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final colors = colorsFor(settings.theme);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Semantics(
                        label: 'Start typing',
                        child: TextField(
                          controller: _controller,
                          onChanged: (text) => _onTextChanged(text, settings),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          autofocus: true,
                          style: _textStyle(settings).copyWith(color: colors.text),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: _charCount,
                      builder: (_, count, _) => count == 0
                          ? ExcludeSemantics(
                              child: Text(
                                'Start typing\u2026',
                                style: _textStyle(settings).copyWith(color: colors.textSecondary),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _charCount,
                    builder: (_, count, _) => Semantics(
                      label: '$count of ${settings.maxChars} characters used',
                      child: Text(
                        '$count / ${settings.maxChars}',
                        style:
                            TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ToolbarButton(
                    icon: Icons.tune,
                    tooltip: 'Change character limit',
                    colors: colors,
                    onPressed: () => _showLimitDialog(context, settings),
                  ),
                  const SizedBox(width: 12),
                  _ToolbarButton(
                    icon: Icons.palette_outlined,
                    tooltip:
                        'Change theme. Current theme is ${settings.theme.label} mode',
                    colors: colors,
                    onPressed: () => _showThemeDialog(context, settings),
                  ),
                  const SizedBox(width: 12),
                  _ToolbarButton(
                    icon: Icons.text_format,
                    tooltip: 'Choose font',
                    colors: colors,
                    onPressed: () => _showFontDialog(context, settings),
                  ),
                  const SizedBox(width: 12),
                  _ToolbarButton(
                    icon: Icons.format_size,
                    tooltip: 'Change font size',
                    colors: colors,
                    onPressed: () => _showFontSizeDialog(context, settings),
                  ),
                  const SizedBox(width: 12),
                  _ToolbarButton(
                    icon: Icons.info_outline,
                    tooltip: 'About Rolling Text',
                    colors: colors,
                    onPressed: () => _showAboutSheet(context, _version),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLimitDialog(BuildContext context, AppSettings settings) async {
    final newLimit = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _NumericSheet(
        title: 'Character Limit',
        hintText: '1 – 1,000,000',
        initialValue: settings.maxChars,
        minValue: 1,
        maxValue: 1000000,
        errorMessage: 'Please enter a number between 1 and 1,000,000',
        colors: colorsFor(settings.theme),
      ),
    );
    if (newLimit != null) _applyNewLimit(newLimit, settings);
  }

  void _applyNewLimit(int newLimit, AppSettings settings) {
    final currentCount = _controller.text.runes.length;

    if (newLimit < currentCount) {
      final charsToRemove = currentCount - newLimit;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Warning'),
          content: Text(
            'This will remove $charsToRemove '
            '${charsToRemove == 1 ? "character" : "characters"} '
            'from the beginning of your text. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                settings.setMaxChars(newLimit);
                widget.prefsService.saveMaxChars(newLimit);
                _onTextChanged(_controller.text, settings);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      settings.setMaxChars(newLimit);
      widget.prefsService.saveMaxChars(newLimit);
    }
  }

  void _showThemeDialog(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Select Theme',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...AppTheme.values.map((theme) {
                final themeColors = colorsFor(theme);
                return ListTile(
                  // Opening on the active row lets arrow keys navigate from
                  // where the user already is. Traversal, the focus highlight
                  // and Enter activation all come from the framework.
                  autofocus: settings.theme == theme,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: themeColors.background,
                      border: Border.all(color: themeColors.text.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(theme.label),
                  trailing: settings.theme == theme ? const Icon(Icons.check) : null,
                  onTap: () {
                    settings.setTheme(theme);
                    widget.prefsService.saveTheme(theme);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showFontDialog(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Text(
                      'Select Font',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _FontList(
                  scrollController: scrollController,
                  selectedFamily: settings.fontFamily,
                  onSelected: (family) {
                    settings.setFontFamily(family);
                    widget.prefsService.saveFontFamily(family);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context, AppSettings settings) {
    double currentSize = settings.fontSize;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${currentSize.round()}pt',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: currentSize.clamp(6, 144),
                  min: 6,
                  max: 144,
                  divisions: 138,
                  label: '${currentSize.round()}pt',
                  onChanged: (value) {
                    setSheetState(() => currentSize = value.roundToDouble());
                    settings.setFontSize(currentSize);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('6pt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('144pt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCustomFontSizeDialog(context, settings);
                  },
                  child: const Text('Enter custom size\u2026'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      widget.prefsService.saveFontSize(settings.fontSize);
    });
  }

  Future<void> _showCustomFontSizeDialog(
    BuildContext context,
    AppSettings settings,
  ) async {
    final newSize = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _NumericSheet(
        title: 'Custom Font Size',
        hintText: '6 – 999',
        initialValue: settings.fontSize.toInt(),
        minValue: 6,
        maxValue: 999,
        errorMessage: 'Please enter a size between 6 and 999 pt',
        colors: colorsFor(settings.theme),
      ),
    );
    if (newSize != null) {
      settings.setFontSize(newSize.toDouble());
      widget.prefsService.saveFontSize(newSize.toDouble());
    }
  }

  void _showAboutSheet(BuildContext context, String version) {
    final settings = context.read<AppSettings>();
    final colors = colorsFor(settings.theme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'About Rolling Text',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  _AboutBodyText(
                    'We all carry thoughts we wish we didn\'t. The worries that '
                    'keep us up at night. The harsh things we say to ourselves. '
                    'The moments we replay over and over even though we can\'t '
                    'change them. That\'s just part of being human, and it can '
                    'be really heavy.',
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _AboutBodyText(
                    'Rolling Text is a simple place to set those thoughts down. '
                    'As you type, your words quietly disappear. Nothing is saved. '
                    'Nothing is stored. You don\'t have to organize your feelings '
                    'or make them make sense. Just let them out, and let them go.',
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _AboutBodyText(
                    'There\'s something powerful about putting a difficult thought '
                    'into words and then watching it leave. You\'re not ignoring '
                    'what you feel. You\'re giving yourself permission to feel it, '
                    'express it, and release it.',
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'And it turns out, science agrees.',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AboutStudy(
                    title: 'Writing down your thoughts and letting them go actually works.',
                    body: 'Researchers found that when people wrote down negative '
                        'thoughts and then discarded them, even digitally by dragging '
                        'them to the recycle bin on a computer, those thoughts lost '
                        'their grip. They had significantly less influence on emotions '
                        'and self-perception afterward. It wasn\'t just the writing '
                        'that helped. It was the act of letting go.',
                    citation: 'Bri\u00f1ol, Petty, Gasc\u00f3 & Horcajo, 2012, Psychological Science',
                    colors: colors,
                  ),
                  _AboutStudy(
                    title: 'Putting your feelings into words is a form of healing.',
                    body: 'Over four decades of research on expressive writing, '
                        'pioneered by psychologist James Pennebaker, has shown that '
                        'writing about what\'s bothering us, even for just a few '
                        'minutes, can meaningfully improve both our emotional and '
                        'physical well-being. You don\'t have to write well. You '
                        'just have to write honestly.',
                    citation: 'Pennebaker, 2018, Perspectives on Psychological Science',
                    colors: colors,
                  ),
                  _AboutStudy(
                    title: 'You are not your thoughts.',
                    body: 'In Acceptance and Commitment Therapy (ACT), a practice '
                        'called cognitive defusion helps people step back and see '
                        'their thoughts for what they really are: passing mental '
                        'events, not permanent truths. Research shows that this kind '
                        'of distance reduces both the pain and the believability of '
                        'harsh, self-critical thoughts more effectively than trying '
                        'to distract yourself or push them away.',
                    citation: 'Masuda et al., 2004, Behavior Therapy; Larsson et al., 2016, Behavior Modification',
                    colors: colors,
                  ),
                  _AboutStudy(
                    title: 'Letting go isn\'t weakness. It\'s a skill.',
                    body: 'A 2023 study from the University of Cambridge found that '
                        'people who practiced actively releasing unwanted thoughts '
                        'experienced less anxiety, less depression, and fewer '
                        'intrusive negative emotions. This was true even for those '
                        'living with clinical mental health conditions. Sometimes '
                        'the bravest thing you can do is choose not to hold on.',
                    citation: 'Mamat et al., 2023, Science Advances',
                    colors: colors,
                  ),
                  _AboutBodyText(
                    'Rolling Text isn\'t therapy, and it\'s not a replacement for '
                    'professional support. If you\'re struggling, please reach out '
                    'to someone who can help. But for the everyday weight of being '
                    'human, for the thoughts that just need somewhere to go, this '
                    'is a quiet place to let them pass through.',
                    colors: colors,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    version.isNotEmpty ? 'Version $version' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// A bottom sheet that collects one whole number in a range.
///
/// Returns the accepted value via [Navigator.pop], so the caller decides what
/// to persist and nothing is committed unless the user applies a valid entry.
/// Stateful so the field's controller and focus node are disposed with the
/// sheet rather than leaking on every open.
class _NumericSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String errorMessage;
  final AppColors colors;

  const _NumericSheet({
    required this.title,
    required this.hintText,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.errorMessage,
    required this.colors,
  });

  @override
  State<_NumericSheet> createState() => _NumericSheetState();
}

class _NumericSheetState extends State<_NumericSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

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

  Future<void> _apply() async {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.minValue || value > widget.maxValue) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: Text(widget.errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // The sheet deliberately stays open: closing it would discard the value
      // the user has just been asked to correct.
      if (!mounted) return;
      _focusNode.requestFocus();
      _selectAll();
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const Spacer(),
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
            onSubmitted: (_) => _apply(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: widget.hintText,
              filled: true,
              fillColor: colors.buttonBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _apply, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }
}

/// The scrolling list of fonts.
///
/// Stateful so it can reveal the active font when the sheet opens. Rows past
/// the viewport are built lazily, and a row that is never built can neither be
/// seen nor take keyboard focus, so a font near the end of the list would
/// otherwise be invisible and unreachable when its own picker opens.
class _FontList extends StatefulWidget {
  final ScrollController scrollController;
  final String? selectedFamily;
  final ValueChanged<String?> onSelected;

  const _FontList({
    required this.scrollController,
    required this.selectedFamily,
    required this.onSelected,
  });

  @override
  State<_FontList> createState() => _FontListState();
}

class _FontListState extends State<_FontList> {
  /// Enforced on the ListView below, so the offset arithmetic in
  /// [_revealSelection] is exact by construction rather than an assumption
  /// about how tall a ListTile happens to render.
  static const double _tileExtent = 56;

  static const List<String?> _options = [null, ...availableFonts];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelection());
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
        return _FontTile(
          label: family ?? 'Source Code Pro (Default)',
          style: GoogleFonts.getFont(family ?? 'Source Code Pro'),
          selected: family == widget.selectedFamily,
          onTap: () => widget.onSelected(family),
        );
      },
    );
  }
}

class _FontTile extends StatelessWidget {
  final String label;
  final TextStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _FontTile({
    required this.label,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Opening on the active row lets arrow keys navigate from where the user
      // already is.
      autofocus: selected,
      title: Text(label, style: style),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final AppColors colors;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.buttonBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: colors.buttonIcon, size: 24),
          ),
        ),
      ),
    );
  }
}

class _AboutBodyText extends StatelessWidget {
  final String text;
  final AppColors colors;

  const _AboutBodyText(this.text, {required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.text,
        fontSize: 16,
        height: 1.4,
      ),
    );
  }
}

class _AboutStudy extends StatelessWidget {
  final String title;
  final String body;
  final String citation;
  final AppColors colors;

  const _AboutStudy({
    required this.title,
    required this.body,
    required this.citation,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          citation,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
