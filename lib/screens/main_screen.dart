import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';


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

  int _codePointCount(String text) => text.runes.length;

  void _onTextChanged(String text, AppSettings settings) {
    if (_isEnforcing) return;

    final count = _codePointCount(text);
    if (count > settings.maxChars) {
      _isEnforcing = true;
      final runes = text.runes.toList();
      final trimmed = String.fromCharCodes(
        runes.sublist(runes.length - settings.maxChars),
      );
      _controller.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      _isEnforcing = false;
    }
    _charCount.value = _codePointCount(_controller.text);
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
                child: TextField(
                  controller: _controller,
                  onChanged: (text) => _onTextChanged(text, settings),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  autofocus: true,
                  style: _textStyle(settings).copyWith(color: colors.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start typing\u2026',
                    hintStyle: _textStyle(settings).copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _charCount,
                    builder: (_, count, __) => Semantics(
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

  void _showLimitDialog(BuildContext context, AppSettings settings) {
    final inputController =
        TextEditingController(text: '${settings.maxChars}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Character Limit',
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
              TextField(
                controller: inputController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '1 \u2013 1,000,000',
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final value = int.tryParse(inputController.text);
                      if (value == null || value < 1 || value > 1000000) {
                        Navigator.pop(ctx);
                        _showErrorDialog(context,
                            'Please enter a number between 1 and 1,000,000');
                        return;
                      }
                      Navigator.pop(ctx);
                      _applyNewLimit(value, settings);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyNewLimit(int newLimit, AppSettings settings) {
    final currentCount = _codePointCount(_controller.text);

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
                child: ListView(
                  controller: scrollController,
                  children: [
                    _FontTile(
                      label: 'Source Code Pro (Default)',
                      style: GoogleFonts.getFont('Source Code Pro'),
                      selected: settings.fontFamily == null,
                      onTap: () {
                        settings.setFontFamily(null);
                        widget.prefsService.saveFontFamily(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...availableFonts.map((family) {
                      return _FontTile(
                        label: family,
                        style: GoogleFonts.getFont(family),
                        selected: settings.fontFamily == family,
                        onTap: () {
                          settings.setFontFamily(family);
                          widget.prefsService.saveFontFamily(family);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
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

  void _showCustomFontSizeDialog(BuildContext context, AppSettings settings) {
    final inputController =
        TextEditingController(text: '${settings.fontSize.toInt()}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 16, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Custom Font Size',
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
              TextField(
                controller: inputController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '6 \u2013 999',
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
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final value = int.tryParse(inputController.text);
                      if (value == null || value < 6 || value > 999) {
                        Navigator.pop(ctx);
                        _showErrorDialog(
                            context, 'Please enter a size between 6 and 999 pt');
                        return;
                      }
                      settings.setFontSize(value.toDouble());
                      widget.prefsService.saveFontSize(value.toDouble());
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid Input'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
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
