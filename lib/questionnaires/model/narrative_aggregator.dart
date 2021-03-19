import 'dart:developer' as developer;

import 'package:fhir/r4.dart';

import '../questionnaires.dart';
import 'aggregator.dart';

/// Create a narrative from the responses to a [Questionnaire].
/// Updates immediately after responses have changed.
class NarrativeAggregator extends Aggregator<Narrative> {
  // TODO: This is currently entirely ineffective. topLocation.revision is always 1-x revisions ahead.
  // Revision of topLocation when _narrative was calculated
  int _revision = -1;
  // Cached narrative
  Narrative? _narrative;

  NarrativeAggregator({bool autoAggregate = true})
      : super(
            Narrative(
                div: '<div xmlns="http://www.w3.org/1999/xhtml"></div>',
                status: NarrativeStatus.empty),
            autoAggregate: autoAggregate);

  @override
  void init(QuestionnaireTopLocation topLocation) {
    super.init(topLocation);

    _revision = -1;
    _narrative = null;

    if (autoAggregate) {
      topLocation.addListener(() => aggregate(notifyListeners: true));
    }
  }

  static bool _addResponseItemToDiv(
      StringBuffer div, QuestionnaireLocation location) {
    final item = location.responseItem;

    if (item == null) {
      return false;
    }

    if (!location.enabled) {
      return false;
    }

    final level = location.level;

    bool returnValue = false;

    if (item.text != null) {
      div.write('<h${level + 2}>${item.text}</h${level + 2}>');
      returnValue = true;
    }

    // TODO(tiloc): Should the conversion from answer to text rather live in classes for the individual types?
    if (item.answer != null) {
      for (final answer in item.answer!) {
        if (answer.valueString != null) {
          div.write('<p>${answer.valueString}</p>');
        } else if (answer.valueDecimal != null) {
          if (location.isCalculatedExpression) {
            div.write('<h3>${answer.valueDecimal.toString()}</h3>');
          } else {
            div.write('<p>${answer.valueDecimal.toString()}</p>');
          }
        } else if (answer.valueQuantity != null) {
          div.write(
              '<p>${answer.valueQuantity!.value} ${answer.valueQuantity!.unit}</p>');
        } else if (answer.valueCoding != null) {
          div.write('<p>${answer.valueCoding!.safeDisplay}</p>');
        } else if (answer.valueDateTime != null) {
          div.write('<p>${answer.valueDateTime}</p>');
        } else if (answer.valueDate != null) {
          div.write('<p>${answer.valueDate}</p>');
        } else if (answer.valueTime != null) {
          div.write('<p>${answer.valueTime}</p>');
        } else if (answer.valueBoolean != null) {
          div.write('<p>${(answer.valueBoolean!.value!) ? '[X]' : '[ ]'}</p>');
        } else {
          div.write('<p>${answer.toString()}</p>');
        }
        returnValue = true;
      }
    }

    return returnValue;
  }

  static Narrative _generateNarrative(QuestionnaireLocation topLocation) {
    final div = StringBuffer('<div xmlns="http://www.w3.org/1999/xhtml">');

    bool generated = false;

    for (final location in topLocation.preOrder()) {
      generated = generated | _addResponseItemToDiv(div, location);
    }
    div.write('</div>');
    return Narrative(
        div: div.toString(),
        status: generated ? NarrativeStatus.generated : NarrativeStatus.empty);
  }

  @override
  Narrative? aggregate({bool notifyListeners = false}) {
    developer.log(
        '$this.aggregate (topRev: ${topLocation.revision}, rev: $_revision)',
        level: LogLevel.trace);
    if (topLocation.revision == _revision) {
      developer.log('Regurgitating narrative revision $_revision');
      return _narrative;
    }
    // Manually invoke the update, because the order matters and enableWhen calcs need to come after answer value updates.
    topLocation.updateEnableWhen(
        notifyListeners:
            false); // TODO: setting this to true will result in endless refresh and stack overflow
    _narrative = _generateNarrative(topLocation);
    _revision = topLocation.revision;
    if (notifyListeners) {
      value = _narrative!;
    }
    return _narrative;
  }
}
