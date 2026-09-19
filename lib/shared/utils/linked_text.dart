import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Ссылка внутри переведённой фразы.
class TextLink {
  const TextLink(this.text, this.recognizer);

  final String text;
  final GestureRecognizer recognizer;
}

/// Собирает фразу со ссылками, не зная порядка слов языка.
///
/// [build] получает маркеры и должен вернуть строку перевода с ними на месте
/// подстановок — например `(m) => l10n.loginConsent(m[0], m[1], m[2])`. По
/// маркерам строка режется на куски, и каждый маркер становится ссылкой из
/// [links] с тем же номером. Так «вы принимаете оферту» и «офертаны
/// қабылдайсыз» живут в одной строке перевода, а не в склейке из кусков.
List<InlineSpan> linkedTextSpans({
  required String Function(List<String> markers) build,
  required List<TextLink> links,
  TextStyle? linkStyle,
}) {
  // Символы из области частного использования в переводе не встречаются.
  final markers = [
    for (var i = 0; i < links.length; i++) String.fromCharCode(0xE000 + i),
  ];
  final text = build(markers);
  final spans = <InlineSpan>[];
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final index = rune - 0xE000;
    if (index >= 0 && index < links.length) {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString()));
        buffer.clear();
      }
      spans.add(TextSpan(
        text: links[index].text,
        style: linkStyle,
        recognizer: links[index].recognizer,
      ));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  if (buffer.isNotEmpty) spans.add(TextSpan(text: buffer.toString()));
  return spans;
}
