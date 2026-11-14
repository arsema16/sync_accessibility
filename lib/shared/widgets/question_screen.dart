import 'package:flutter/material.dart';

import '../../core/access/access_callbacks.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import 'form_step.dart';

/// A reusable form engine that shows one [FormStep] at a time.
///
/// Accessibility features:
///   - Progress is shown visually and announced via a [Semantics] live region.
///   - Every interactive control meets the 48dp minimum tap target.
///   - Error messages use an icon AND text (never colour alone) and are
///     announced via a [Semantics] live region.
///   - There are no forced timeouts anywhere.
///   - Voice input is always paired with a typed fallback text field.
class QuestionScreen extends StatefulWidget {
  const QuestionScreen({
    super.key,
    required this.steps,
    required this.onComplete,
    this.flowTitle,
    this.initialAnswers,
    this.finalStepLabel = AppStrings.continueLabel,
    VoiceInputCallback? voiceInput,
  }) : voiceInput = voiceInput ?? _noVoiceInput;

  final List<FormStep> steps;
  final void Function(Map<String, Object> answers) onComplete;
  final String? flowTitle;

  /// Answers restored when the flow is re-entered (e.g. after editing a
  /// section). Keys are the [FormStep.id]s.
  final Map<String, Object>? initialAnswers;

  /// Label shown on the advance button at the final step.
  final String finalStepLabel;

  /// Injected voice capability. The stub returns an empty string; Bethel wires
  /// the real speech API. Typed fallback is always available regardless.
  final VoiceInputCallback voiceInput;

  static Future<String> _noVoiceInput() async => '';

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final TextEditingController _textController = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  int _current = 0;
  late final Map<String, Object> _answers =
      Map<String, Object>.from(widget.initialAnswers ?? const {});
  String? _error;
  bool _isListening = false;
  bool _showVoiceHint = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _loadCurrentIntoController();
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
        _loadCurrentIntoController();
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
        _loadCurrentIntoController();
      });
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
      final result = await widget.voiceInput();
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
        // The stub returns empty; surface that typed fallback is the way.
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: widget.flowTitle == null ? null : Text(widget.flowTitle!),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            label: AppStrings.stepProgress(_current + 1, _total),
            child: Text(
              AppStrings.stepProgressLabel(_current + 1, _total),
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: LinearProgressIndicator(
              value: (_current + 1) / _total,
              minHeight: 8,
            ),
          ),
        ],
      ),
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
          child: Text(step.title, style: theme.textTheme.headlineMedium),
        ),
        if (step.hint != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(step.hint!, style: theme.textTheme.bodyMedium),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(theme),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final option in step.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OptionTile(
              option: option,
              multi: multi,
              selected: multi
                  ? (current is List && current.contains(option.id))
                  : current == option.id,
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
          ),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          keyboardType: _step.keyboardType ?? TextInputType.text,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: _step.title,
            hintText: _step.hint,
            errorText: _error,
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
            errorText: _error,
          ),
          onSubmitted: (_) => _advance(),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: AppStrings.tapToSpeak,
          hint: AppStrings.tapToSpeak,
          button: true,
          child: FilledButton.tonalIcon(
            onPressed: _isListening ? null : _startVoice,
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            label: Text(_isListening ? AppStrings.listening : AppStrings.tapToSpeak),
          ),
        ),
        if (_showVoiceHint) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.voiceUnavailable, style: theme.textTheme.bodySmall),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildError(theme),
        ],
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

/// A single selectable option row. Combines its icon, label and description
/// into one semantics node with a clear selected/not-selected value.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.multi,
  });

  final FormOption option;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = multi
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      hint: option.description,
      value: selected ? AppStrings.stateSelected : AppStrings.stateNotSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : null,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 2 : 1.4,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.onSurface),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.labelLarge,
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        option.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
