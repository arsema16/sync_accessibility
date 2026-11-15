import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_callbacks.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'form_step.dart';
import 'sync_info_banner.dart';
import 'sync_option_card.dart';
import 'sync_voice_mic_button.dart';

/// A reusable form engine that shows one [FormStep] at a time.
///
/// Accessibility features:
///   - Progress is shown visually and announced via a [Semantics] live region.
///   - Every interactive control meets the 48dp minimum tap target.
///   - Error messages use an icon AND text (never colour alone) and are
///     announced via a [Semantics] live region. They are NOT also rendered as
///     Material `errorText` (which is colour-only and would duplicate the
///     accessible copy).
///   - Progress and loading indicators honour [MediaQuery.disableAnimations]:
///     when the OS asks for reduced motion the progress bar is drawn as a
///     static fraction instead of animating.
///   - There are no forced timeouts anywhere.
///   - Voice input is always paired with a typed fallback text field.
///   - Read-aloud fires on each step if the user has enabled that preference.
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({
    super.key,
    required this.steps,
    required this.onComplete,
    this.flowTitle,
    this.initialAnswers,
    this.finalStepLabel = AppStrings.continueLabel,
  });

  final List<FormStep> steps;
  final void Function(Map<String, Object> answers) onComplete;
  final String? flowTitle;

  /// Answers restored when the flow is re-entered (e.g. after editing a
  /// section). Keys are the [FormStep.id]s.
  final Map<String, Object>? initialAnswers;

  /// Label shown on the advance button at the final step.
  final String finalStepLabel;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  late final TextEditingController _textController = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  int _current = 0;
  late final Map<String, Object> _answers =
      Map<String, Object>.from(widget.initialAnswers ?? const {});
  String? _error;
  bool _isListening = false;
  String? _voiceHint;
  bool _showTextField = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _loadCurrentIntoController();
    // Defer TTS until after the first frame so it never fires mid-layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readCurrentTitle();
    });
  }

  void _onTextChanged() {
    if (_voiceHint != null && _textController.text.isNotEmpty) {
      setState(() => _voiceHint = null);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  FormStep get _step => widget.steps[_current];
  int get _total => widget.steps.length;

  bool get _isLast => _current == widget.steps.length - 1;

  /// Whether the Access Passport asks for plain, simple wording.
  bool get _simplerWording =>
      ref.read(accessPreferencesNotifierProvider).simplerWording;

  /// The heading for [step], swapping in the simple variant when the user
  /// has enabled simpler wording and one is provided.
  String _titleFor(FormStep step) =>
      _simplerWording && step.simpleTitle != null
          ? step.simpleTitle!
          : step.title;

  /// The hint for [step] — see [_titleFor].
  String? _hintFor(FormStep step) =>
      _simplerWording && step.simpleHint != null ? step.simpleHint! : step.hint;

  void _readCurrentTitle() {
    final access = ref.read(accessPreferencesNotifierProvider);
    if (access.readAloud) {
      ref.read(readAloudProvider)(_titleFor(_step));
    }
  }

  void _loadCurrentIntoController() {
    if (_step.inputType == FormInputType.text ||
        _step.inputType == FormInputType.voice) {
      final existing = _answers[_step.id];
      _textController.text = existing is String ? existing : '';
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    } else {
      _textController.clear();
    }
  }

  void _captureCurrentText() {
    if (_step.inputType == FormInputType.text ||
        _step.inputType == FormInputType.voice) {
      _answers[_step.id] = _textController.text.trim();
    }
  }

  String? _validate() {
    final step = _step;
    switch (step.inputType) {
      case FormInputType.text:
      case FormInputType.voice:
        final value = _textController.text.trim();
        if (step.validator != null) {
          return step.validator!(value);
        }
        if (step.required && value.isEmpty) {
          return AppStrings.requiredError;
        }
        return null;
      case FormInputType.choice:
        if (step.required && _answers[step.id] == null) {
          return AppStrings.chooseOptionError;
        }
        return null;
      case FormInputType.multiChoice:
        final selected = _answers[step.id];
        if (step.required && (selected is! List || selected.isEmpty)) {
          return AppStrings.chooseOptionError;
        }
        return null;
    }
  }

  void _advance() {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _captureCurrentText();
    setState(() => _error = null);
    if (!_isLast) {
      setState(() {
        _current += 1;
        _showTextField = false;
        _loadCurrentIntoController();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _readCurrentTitle();
      });
      if (_step.inputType == FormInputType.text ||
          _step.inputType == FormInputType.voice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      }
    } else {
      widget.onComplete(Map<String, Object>.from(_answers));
    }
  }

  void _goBack() {
    if (_current > 0) {
      setState(() {
        _current -= 1;
        _showTextField = false;
        _loadCurrentIntoController();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _readCurrentTitle();
      });
    } else {
      context.pop();
    }
  }

  Future<void> _startVoice() async {
    setState(() {
      _isListening = true;
      _voiceHint = null;
    });
    try {
      final voiceInput = ref.read(voiceInputProvider);
      final result = await voiceInput();
      if (!mounted) {
        return;
      }
      if (result.text.trim().isNotEmpty) {
        final existing = _textController.text.trim();
        _textController.text = existing.isEmpty
            ? result.text.trim()
            : '$existing ${result.text.trim()}';
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      } else {
        // Nothing heard after the retry budget, or no recogniser at all —
        // say which, so "we missed you" never reads as "feature broken".
        setState(() {
          _voiceHint = result.status == VoiceInputStatus.noSpeech
              ? AppStrings.voiceNoSpeech
              : AppStrings.voiceUnavailable;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch so switching simpler wording mid-flow re-renders the current step.
    ref.watch(accessPreferencesNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.pageGradientEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pageGradientStart, AppColors.pageGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(36)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowSoft,
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildProgress(theme),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildStepContent(context, theme),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNavRow(context, theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Card header: back affordance, then the flow title (or the SYNC wordmark)
  /// centred, with a matching spacer on the right so it stays centred.
  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: AppStrings.goBack,
            onPressed: _goBack,
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.cardInk,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              widget.flowTitle ?? 'SYNC',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.cardInk,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  /// Title + hint styling shared by every step type, so all steps share the
  /// same rhythm regardless of input type.
  static const TextStyle _titleStyle = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.cardInk,
  );

  static const TextStyle _hintStyle = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.cardInkMuted,
  );

  Widget _buildProgress(ThemeData theme) {
    final fraction = (_current + 1) / _total;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rounded step progress, full card width.
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: disableAnimations
                ? ColoredBox(
                    color: AppColors.cardTrack,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        child: const ColoredBox(color: AppColors.primary),
                      ),
                    ),
                  )
                : LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: AppColors.cardTrack,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          liveRegion: true,
          label: AppStrings.stepProgress(_current + 1, _total),
          child: Text(
            AppStrings.stepProgressLabel(_current + 1, _total),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.cardInkMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context, ThemeData theme) {
    final step = _step;
    switch (step.inputType) {
      case FormInputType.choice:
        return _buildChoice(theme, multi: false);
      case FormInputType.multiChoice:
        return _buildChoice(theme, multi: true);
      case FormInputType.text:
        return _buildTextField(theme);
      case FormInputType.voice:
        return _buildVoiceField(theme);
    }
  }

  Widget _buildChoice(ThemeData theme, {required bool multi}) {
    final step = _step;
    final current = _answers[step.id];
    final title = _titleFor(step);
    final hint = _hintFor(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: _titleStyle,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            hint,
            style: _hintStyle,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(theme),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final option in step.options)
          SyncOptionCard(
            icon: _iconForOption(option.id),
            label: option.label,
            description: option.description,
            selected: multi
                ? (current is List && current.contains(option.id))
                : current == option.id,
            multi: multi,
            onTap: () {
              setState(() {
                _error = null;
                if (multi) {
                  final list = (current is List)
                      ? List<String>.from(current)
                      : <String>[];
                  if (list.contains(option.id)) {
                    list.remove(option.id);
                  } else {
                    list.add(option.id);
                  }
                  _answers[step.id] = list;
                } else {
                  _answers[step.id] = option.id;
                }
              });
            },
          ),
      ],
    );
  }

  IconData _iconForOption(String id) {
    // Provide sensible default icons for common option IDs
    switch (id) {
      case 'nationalId':
        return Icons.credit_card;
      case 'refugeeId':
        return Icons.people;
      case 'otherDocument':
        return Icons.description;
      case 'partnerReferral':
        return Icons.handshake;
      case 'primary':
      case 'secondary':
      case 'vocational':
      case 'university':
      case 'noneOrOther':
        return Icons.school;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _buildTextField(ThemeData theme) {
    final title = _titleFor(_step);
    final hint = _hintFor(_step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: _titleStyle,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            hint,
            style: _hintStyle,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          keyboardType: _step.keyboardType ?? TextInputType.text,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: title,
            hintText: hint,
          ),
          onSubmitted: (_) => _advance(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Voice input on every field: speak instead of typing. The typed
        // answer above always remains editable.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, AppSpacing.minTapTarget),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
              onPressed: _isListening ? null : _startVoice,
              icon: _isListening
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic_none, size: 20),
              label: Text(_isListening ? AppStrings.listening : AppStrings.speakInstead),
            ),
            if (_voiceHint != null)
              Text(
                _voiceHint!,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        if (_error != null) _buildError(theme),
      ],
    );
  }

  Widget _buildVoiceField(ThemeData theme) {
    final title = _titleFor(_step);
    final hint = _hintFor(_step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: _titleStyle,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            hint,
            style: _hintStyle,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // Centered mic button — SyncVoiceMicButton handles its own tap via
        // GestureDetector; it has explicit 120×120 dimensions so layout is
        // always defined before any hit-test runs.
        Center(
          child: SyncVoiceMicButton(
            isListening: _isListening,
            onTap: _isListening ? null : _startVoice,
          ),
        ),
        if (_isListening) ...[
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Listening...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.cardInkMuted,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // "Type instead" pill button
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardAqua,
              foregroundColor: AppColors.cardInk,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
            ),
            onPressed: () => setState(() => _showTextField = !_showTextField),
            icon: const Icon(Icons.keyboard, size: 18),
            label: const Text('Type instead'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // TextField shown only after "Type instead" is tapped
        if (_showTextField) ...[
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            keyboardType: _step.keyboardType ?? TextInputType.text,
            textInputAction: TextInputAction.next,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: title,
              hintText: hint,
            ),
            onSubmitted: (_) => _advance(),
          ),
        ],
        if (_voiceHint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_voiceHint!, style: theme.textTheme.bodySmall),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(theme),
        ],
        const SizedBox(height: AppSpacing.lg),
        const SyncInfoBanner(
          message: 'Your voice will be converted to text automatically.',
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: _error,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _error ?? '',
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (_current > 0)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(80, AppSpacing.minTapTarget),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.cardInk,
              side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
            ),
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 14),
            label: const Text(AppStrings.back),
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, AppSpacing.minTapTarget),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _advance,
          icon: const Icon(Icons.arrow_forward_ios, size: 14),
          label: Text(_isLast ? widget.finalStepLabel : AppStrings.next),
        ),
      ],
    );
  }
}
