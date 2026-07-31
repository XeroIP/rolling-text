import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_truncation.dart';

class MainScreen extends StatefulWidget {
  final PreferencesService prefsService;

  const MainScreen({super.key, required this.prefsService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final ValueNotifier<int> _charCount = ValueNotifier<int>(0);
  bool _isEnforcing = false;
  String _version = '';
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() => _version = info.version);
    });
    // Returning to the app (another window regains focus, or the OS resumes
    // the app on mobile) does not by itself give the editor focus back. Left
    // alone, that reproduces the same dead-input state as #29's tap-outside
    // case: the FocusNode can still report focused while nothing is actually
    // listening for keystrokes.
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _editorFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _editorFocusNode.dispose();
    _controller.dispose();
    _charCount.dispose();
    super.dispose();
  }

  /// Shows a bottom sheet and waits until it has fully gone away.
  ///
  /// showModalBottomSheet returns the route's `popped` future, which completes
  /// while the sheet is still animating out and before the sheet disposes its
  /// own focus nodes. Restoring editor focus at that point is silently undone
  /// by the departing sheet -- observed in Chrome with the numeric sheets,
  /// which own a text field. Awaiting TransitionRoute.completed instead means
  /// the sheet is really gone before focus is restored.
  Future<T?> _showSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) async {
    final navigator = Navigator.of(context);
    final localizations = MaterialLocalizations.of(context);
    final route = ModalBottomSheetRoute<T>(
      builder: builder,
      isScrollControlled: isScrollControlled,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
    );
    final result = await navigator.push(route);
    await route.completed;
    return result;
  }

  /// Returns text input to the editor after a sheet closes. Web only.
  ///
  /// Flutter restores framework focus on its own when a route pops, and on
  /// native platforms that is sufficient -- ModalRoute hands focus back to the
  /// editor with a live input connection. On Web it is not enough: the editor's
  /// FocusNode reports focus while the browser is left with no focused input
  /// element, so the next keystroke goes nowhere. Verified in Chrome against
  /// this build -- the hidden textarea Flutter uses for text input is focused
  /// on load and unfocused after a sheet is dismissed, so a bare requestFocus()
  /// would be a no-op. Cycling unfocus, then a frame, then refocus forces
  /// EditableText to re-establish its input connection.
  ///
  /// The kIsWeb gate is load-bearing, not a micro-optimisation. Running this on
  /// Android closes and reopens the software keyboard on every sheet dismissal,
  /// a visible flicker confirmed on a Pixel 8 Pro release build. Do not remove
  /// the gate to "simplify" the platform split.
  ///
  /// Equally, do not delete the body on the strength of a green test run:
  /// widget tests run on the native platform, where this no-ops, and cannot
  /// observe browser focus. Re-check in a real browser instead.
  Future<void> _restoreEditorFocus() async {
    if (!kIsWeb) return;
    if (!mounted) return;
    _editorFocusNode.unfocus();
    // endOfFrame schedules a frame if none is pending; addPostFrameCallback
    // does not, and would strand this when the app is idle.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _editorFocusNode.requestFocus();

    // The draggable sheets (Font, About) tear down over one more frame than the
    // plain ones, and that teardown drops the connection just restored above.
    // Observed in Chrome: without this second pass, dismissing either of those
    // two with Escape leaves the editor untypeable while the others are fine.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _editorFocusNode.requestFocus();
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
                          focusNode: _editorFocusNode,
                          onChanged: (text) => _onTextChanged(text, settings),
                          // The default TapRegion behaviour unfocuses the field
                          // on an outside tap. That is #29: nothing ever
                          // requests focus again afterward, so typing goes
                          // nowhere until the page reloads. Re-requesting focus
                          // here instead keeps the editor the permanent target
                          // for keystrokes, which matches an app with no other
                          // text input to tap into.
                          onTapOutside: (_) => _editorFocusNode.requestFocus(),
                          // "Nothing is saved. Nothing is stored" is the whole
                          // premise of this app; leaving IME personalized
                          // learning on would let the keyboard itself add typed
                          // text to its dictionary and suggestion history. This
                          // opts out of that without touching autocorrect or
                          // suggestions, which are a separate decision.
                          enableIMEPersonalizedLearning: false,
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

  /// Awaits a preference write and warns if it silently failed.
  ///
  /// The setting stays applied for this session either way -- reverting the
  /// UI back to its old value on a storage failure would be a worse
  /// experience than a value that just does not survive to the next launch.
  /// PreferencesService's save methods report success or failure instead of
  /// being fire-and-forget specifically so this can tell the difference.
  Future<void> _persist(Future<bool> Function() save, BuildContext context) async {
    final saved = await save();
    if (saved || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This change won't be remembered")),
    );
  }

  Future<void> _showLimitDialog(BuildContext context, AppSettings settings) async {
    final newLimit = await _showSheet<int>(
      isScrollControlled: true,
      builder: (ctx) => _NumericSheet(
        title: 'Character Limit',
        hintText: '1 – 1,000,000',
        initialValue: settings.maxChars,
        minValue: minMaxChars,
        maxValue: maxMaxChars,
        errorMessage: 'Please enter a number between 1 and 1,000,000',
        colors: colorsFor(settings.theme),
      ),
    );
    if (!context.mounted) return;
    if (newLimit != null) _applyNewLimit(newLimit, settings, context);
    await _restoreEditorFocus();
  }

  /// Applies a new limit, shortening the text if it no longer fits.
  ///
  /// A lower limit takes effect without confirmation: this editor exists to make
  /// text disappear, so asking permission to shorten it works against the point.
  /// _onTextChanged truncates when the text is over the limit and does nothing
  /// when it is not, so one call covers both cases.
  void _applyNewLimit(int newLimit, AppSettings settings, BuildContext context) {
    settings.setMaxChars(newLimit);
    _persist(() => widget.prefsService.saveMaxChars(newLimit), context);
    _onTextChanged(_controller.text, settings);
  }

  Future<void> _showThemeDialog(BuildContext context, AppSettings settings) async {
    await _showSheet<void>(
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return Shortcuts(
          shortcuts: _rowTraversalShortcuts,
          child: _SheetInitialFocus(
          builder: (rowFocusNode) => Padding(
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
                  // and Enter activation all come from the framework; only the
                  // initial claim is ours -- see _SheetInitialFocus.
                  focusNode: settings.theme == theme ? rowFocusNode : null,
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
                    Navigator.pop(ctx);
                    _persist(() => widget.prefsService.saveTheme(theme), context);
                  },
                );
              }),
            ],
          ),
          ),
          ),
        );
      },
    );
    await _restoreEditorFocus();
  }

  Future<void> _showFontDialog(BuildContext context, AppSettings settings) async {
    await _showSheet<void>(
      isScrollControlled: true,
      builder: (ctx) {
        final colors = colorsFor(settings.theme);
        return Shortcuts(
          shortcuts: _rowTraversalShortcuts,
          child: DraggableScrollableSheet(
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
                    Navigator.pop(ctx);
                    _persist(() => widget.prefsService.saveFontFamily(family), context);
                  },
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
    await _restoreEditorFocus();
  }

  Future<void> _showFontSizeDialog(
    BuildContext context,
    AppSettings settings,
  ) async {
    // The sheet previews sizes live, so a dismissal has to undo the preview.
    // Only Apply (and the Enter that stands in for it) pops true.
    final originalSize = settings.fontSize;
    final applied = await _showSheet<bool>(
      // Required because this sheet owns a text field whose autofocus raises
      // the keyboard immediately. Without it the sheet is capped at 9/16 of
      // the screen and laid out against the unreduced bottom edge, which put
      // it entirely underneath the keyboard -- see the viewInsets padding in
      // _FontSizeSheet.build. Both halves are needed; neither works alone.
      isScrollControlled: true,
      builder: (ctx) => _FontSizeSheet(
        settings: settings,
        colors: colorsFor(settings.theme),
      ),
    );
    if (!context.mounted) return;
    if (applied != true) settings.setFontSize(originalSize);
    _persist(() => widget.prefsService.saveFontSize(settings.fontSize), context);
    await _restoreEditorFocus();
  }

  Future<void> _showAboutSheet(BuildContext context, String version) async {
    final settings = context.read<AppSettings>();
    final colors = colorsFor(settings.theme);

    await _showSheet<void>(
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => CallbackShortcuts(
          // Flutter's own ScrollAction resolves its target by walking UP from
          // the focused node, so arrows only scroll while something inside the
          // list holds focus. This list is lazy: an anchor placed in it is
          // unmounted once scrolled past the cache extent, and the arrows then
          // die partway down while the mouse wheel keeps working. Driving the
          // controller costs a little arithmetic but never depends on where
          // focus sits. The Focus below exists only so key events arrive.
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                () => _scrollAbout(scrollController, _aboutArrowStep),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                () => _scrollAbout(scrollController, -_aboutArrowStep),
            const SingleActivator(LogicalKeyboardKey.pageDown):
                () => _scrollAbout(scrollController, _aboutPageStep(scrollController)),
            const SingleActivator(LogicalKeyboardKey.pageUp):
                () => _scrollAbout(scrollController, -_aboutPageStep(scrollController)),
          },
          child: Focus(
            autofocus: true,
            child: Column(
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
        ),
      ),
    );
    await _restoreEditorFocus();
  }

  /// Makes bare arrow keys move focus between rows in a picker sheet.
  ///
  /// Required on Web and nowhere else. WidgetsApp.defaultShortcuts returns
  /// _defaultWebShortcuts when kIsWeb, and that map binds bare arrows to
  /// ScrollIntent -- only Tab and Shift+Tab traverse focus. The non-web maps bind
  /// arrows to DirectionalFocusIntent, which is why every widget test passes
  /// while the browser cannot select a theme or font at all: in the Theme sheet
  /// the arrows hit a non-scrolling Column and do nothing, and in the Font sheet
  /// they scroll the list without moving the selection.
  ///
  /// Verified in Chrome: an ArrowUp with the Theme sheet open arrived at
  /// flutter-view with defaultPrevented still false, i.e. the framework declined
  /// it, and the focus highlight never left the active row.
  ///
  /// DirectionalFocusAction is already in the default Actions map, so supplying
  /// the intent is all this needs.
  static const Map<ShortcutActivator, Intent> _rowTraversalShortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
      TraversalDirection.up,
    ),
  };

  /// One arrow press worth of About-sheet scrolling, in logical pixels.
  static const double _aboutArrowStep = 80;

  /// One page press worth, scaled to whatever the sheet is currently showing so
  /// it always outruns an arrow press.
  double _aboutPageStep(ScrollController controller) =>
      controller.hasClients ? controller.position.viewportDimension * 0.8 : 0;

  /// Scrolls the About sheet by [delta], clamped to the content.
  void _scrollAbout(ScrollController controller, double delta) {
    if (!controller.hasClients) return;
    final position = controller.position;
    controller.animateTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }
}

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
class _SheetInitialFocus extends StatefulWidget {
  final Widget Function(FocusNode rowFocusNode) builder;

  const _SheetInitialFocus({required this.builder});

  @override
  State<_SheetInitialFocus> createState() => _SheetInitialFocusState();
}

class _SheetInitialFocusState extends State<_SheetInitialFocus> {
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

/// The Font Size sheet: a numeric field and a slider that both edit the same
/// value live, kept in sync with each other.
///
/// The field is autofocused with its value preselected, so the sheet is
/// typeable the instant it opens -- no button, no second sheet to reach a
/// keyboard. Field precedes the slider in the widget tree, so a single Tab
/// from the field reaches the slider.
class _FontSizeSheet extends StatefulWidget {
  final AppSettings settings;
  final AppColors colors;

  const _FontSizeSheet({required this.settings, required this.colors});

  @override
  State<_FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<_FontSizeSheet> {
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
      // exactly as _NumericSheet does. Pairs with isScrollControlled: true at
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
              Text('6pt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Text('144pt', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ],
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
      ),
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

  final FocusNode _selectedNode = FocusNode(debugLabel: 'selected font');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _revealSelection();
      // The jump above changes which rows exist, so the selected row is only
      // built on the frame after it. Requesting focus any earlier targets a node
      // with no context. See _SheetInitialFocus for why autofocus is not enough.
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
        return _FontTile(
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

class _FontTile extends StatelessWidget {
  final String label;
  final TextStyle style;
  final bool selected;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const _FontTile({
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
      // see _SheetInitialFocus.
      focusNode: focusNode,
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
