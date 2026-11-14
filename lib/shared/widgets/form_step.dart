import 'package:flutter/material.dart';

/// The kind of input a [FormStep] collects.
enum FormInputType { text, choice, multiChoice, voice }

/// One selectable option for choice / multiChoice steps.
class FormOption {
  const FormOption({
    required this.id,
    required this.label,
    this.description,
  });

  /// Value stored in the answers map when this option is chosen.
  final String id;

  /// Text shown to the user.
  final String label;

  /// Optional plain-language explanation shown under the label.
  final String? description;
}

/// A single question shown by [QuestionScreen].
class FormStep {
  const FormStep({
    required this.id,
    required this.title,
    required this.inputType,
    this.hint,
    this.options = const <FormOption>[],
    this.keyboardType,
    this.validator,
    this.required = true,
  });

  /// Key used to store this step's answer in the answers map.
  final String id;

  /// The question text, shown as a heading.
  final String title;

  /// Optional helper text under the heading.
  final String? hint;

  final FormInputType inputType;

  /// Options for [FormInputType.choice] / [FormInputType.multiChoice].
  final List<FormOption> options;

  /// Keyboard type for [FormInputType.text] / [FormInputType.voice].
  final TextInputType? keyboardType;

  /// Optional validator for text / voice answers. Receives the trimmed value
  /// and returns an error message, or `null` when valid. When omitted, a
  /// required step just needs a non-empty answer.
  final String? Function(String value)? validator;

  /// Whether an answer is required to advance.
  final bool required;
}
