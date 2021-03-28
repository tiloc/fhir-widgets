import 'package:fhir/r4.dart';
import 'package:flutter/material.dart';

import 'fhir_types_extensions.dart';

class CodeableConceptWidget extends StatelessWidget {
  final CodeableConcept codeableConcept;
  final TextStyle? style;

  const CodeableConceptWidget(this.codeableConcept, {this.style, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      codeableConcept.localizedDisplay(Localizations.localeOf(context)),
      style: style,
    );
  }
}
