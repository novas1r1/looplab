import 'package:flutter/material.dart';
// Import the widget from your app
import 'package:repeatlab/core/ui/interaction/primary_button.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Active', type: PrimaryButton)
Widget primaryButton(BuildContext context) {
  return PrimaryButton(
    onPressed: () {},
    text: context.knobs.string(label: 'Title Label', initialValue: 'HomePage'),
  );
}

@UseCase(name: 'Disabled', type: PrimaryButton)
Widget primaryButtonDisabled(BuildContext context) {
  return PrimaryButton(
    onPressed: null,
    text: context.knobs.string(label: 'Title Label', initialValue: 'HomePage'),
  );
}
