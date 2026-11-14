import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _showVoiceHint = false;
  bool _showTextField = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _loadCurrentIntoController();
    _readCurrentTitle();
  }

  void _onTextChanged() {
    if (_showVoiceHint && _textController.text.isNotEmpty) {
      setState(() => _showVoiceHint = false);
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

  void _readCurrentTitle() {
    final access = ref.read(accessPreferencesNotifierProvider);
    if (access.readAloud) {
      ref.read(readAloudProvider)(_step.title);
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
      _readCurrentTitle();
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
      _readCurrentTitle();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _startVoice() async {
    setState(() {
      _isListening = true;
      _showVoiceHint = false;
    });
    try {
      final voiceInput = ref.read(voiceInputProvider);
      final result = await voiceInput();
      if (!mounted) {
        return;
      }
      if (result.trim().isNotEmpty) {
        final existing = _textController.text.trim();
        _textController.text = existing.isEmpty
            ? result.trim()
            : '$existing ${result.trim()}';
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      } else {
        // No result or STT unavailable; show typed-fallback hint.
        setState(() => _showVoiceHint = true);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: widget.flowTitle == null ? null : Text(widget.flowTitle!),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: AppStrings.goBack,
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgress(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: _buildStepContent(context, theme),
              ),
            ),
            _buildNavRow(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    final fraction = (_current + 1) / _total;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thin teal progress bar at very top, full-width
        disableAnimations
            ? SizedBox(
                height: 6,
                child: ColoredBox(
                  color: const Color(0xFFE0E0E0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      child: const ColoredBox(color: AppColors.primary),
                    ),
                  ),
                ),
              )
            : LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.xs,
          ),
          child: Semantics(
            liveRegion: true,
            label: AppStrings.stepProgress(_current + 1, _total),
            child: Text(
              AppStrings.stepProgressLabel(_current + 1, _total),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            step.title,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        if (step.hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.hint!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF757575),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            _step.title,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        if (_step.hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _step.hint!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF757575),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          keyboardType: _step.keyboardType ?? TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: _step.title,
            hintText: _step.hint,
          ),
          onSubmitted: (_) => _advance(),
        ),
        if (_error != null) _buildError(theme),
      ],
    );
  }

  Widget _buildVoiceField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            _step.title,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        if (_step.hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _step.hint!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF757575),
            ),
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
                color: Color(0xFF757575),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // "Type instead" pill button
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: const Color(0xFF1A1A1A),
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
            decoration: InputDecoration(
              labelText: _step.title,
              hintText: _step.hint,
            ),
            onSubmitted: (_) => _advance(),
          ),
        ],
        if (_showVoiceHint) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.voiceUnavailable, style: theme.textTheme.bodySmall),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Row(
        children: [
          if (_current > 0)
            OutlinedButton(
              onPressed: _goBack,
              child: Text(AppStrings.back),
            )
          else
            const SizedBox(width: 0),
          const Spacer(),
          FilledButton(
            onPressed: _advance,
            child: Text(_isLast ? widget.finalStepLabel : AppStrings.next),
          ),
        ],
      ),
    );
  }
}
