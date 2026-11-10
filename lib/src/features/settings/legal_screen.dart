import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/tokens.g.dart';
import 'legal_texts.dart';

enum LegalDoc { privacy, terms }

/// Toàn văn [doc] theo ngôn ngữ app (`vi` dùng bản tiếng Việt, còn lại tiếng Anh).
String legalText(LegalDoc doc, String localeName) {
  final vi = localeName.startsWith('vi');
  return switch (doc) {
    LegalDoc.privacy => vi ? LegalTexts.privacyVi : LegalTexts.privacyEn,
    LegalDoc.terms => vi ? LegalTexts.termsVi : LegalTexts.termsEn,
  };
}

/// Bản nhúng của Chính sách quyền riêng tư / Điều khoản sử dụng (AC-41, D-039):
/// đọc được khi trang công khai không mở được hoặc máy đang offline.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  static Route<void> route(LegalDoc doc) =>
      MaterialPageRoute(builder: (_) => LegalScreen(doc: doc));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final blocks = LegalMarkdown.parse(legalText(doc, l.localeName));
    return Scaffold(
      appBar: AppBar(
        title: Text(doc == LegalDoc.privacy ? l.privacyPolicy : l.terms),
      ),
      body: SafeArea(
        top: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s2,
              VgSpace.s4,
              VgSpace.s8,
            ),
            children: [for (final b in blocks) _Block(b)],
          ),
        ),
      ),
    );
  }
}

enum LegalBlockKind { title, heading, paragraph, bullet, numbered }

class LegalBlock {
  const LegalBlock(this.kind, this.text, {this.number});

  final LegalBlockKind kind;

  /// Markdown nội dòng (`**đậm**`, `[chữ](href)`) còn nguyên.
  final String text;
  final String? number;
}

/// Bộ đọc Markdown dùng trong `store/legal`: tiêu đề `#`/`##`, đoạn văn (nối
/// các dòng ngắt tay), gạch đầu dòng `- ` và mục số `1. ` có dòng nối thụt vào.
abstract final class LegalMarkdown {
  static final _numbered = RegExp(r'^(\d+)\.\s+(.*)$');

  static List<LegalBlock> parse(String md) {
    final out = <LegalBlock>[];
    LegalBlockKind? kind;
    String? number;
    final buf = <String>[];

    void flush() {
      if (kind != null && buf.isNotEmpty) {
        out.add(LegalBlock(kind!, buf.join(' '), number: number));
      }
      kind = null;
      number = null;
      buf.clear();
    }

    for (final raw in md.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      final t = line.trimLeft();
      if (t.isEmpty) {
        flush();
      } else if (t.startsWith('## ')) {
        flush();
        out.add(LegalBlock(LegalBlockKind.heading, t.substring(3).trim()));
      } else if (t.startsWith('# ')) {
        flush();
        out.add(LegalBlock(LegalBlockKind.title, t.substring(2).trim()));
      } else if (t.startsWith('- ')) {
        flush();
        kind = LegalBlockKind.bullet;
        buf.add(t.substring(2).trim());
      } else if (_numbered.hasMatch(t) && line == t) {
        flush();
        final m = _numbered.firstMatch(t)!;
        kind = LegalBlockKind.numbered;
        number = m.group(1);
        buf.add(m.group(2)!.trim());
      } else {
        // Dòng nối của mục (thụt vào) hoặc của đoạn văn.
        if (kind == null || (line == t && kind != LegalBlockKind.paragraph)) {
          flush();
          kind = LegalBlockKind.paragraph;
        }
        buf.add(t);
      }
    }
    flush();
    return out;
  }

  static final _inline = RegExp(r'\*\*(.+?)\*\*|\[(.+?)\]\((.+?)\)');

  /// Đoạn nội dòng: `**…**` thành đậm; link chỉ giữ chữ (trong app hai văn bản
  /// nằm cạnh nhau ở Cài đặt nên không cần mở link).
  static List<InlineSpan> spans(String text, TextStyle bold) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > i) out.add(TextSpan(text: text.substring(i, m.start)));
      out.add(
        m.group(1) != null
            ? TextSpan(text: m.group(1), style: bold)
            : TextSpan(text: m.group(2)),
      );
      i = m.end;
    }
    if (i < text.length) out.add(TextSpan(text: text.substring(i)));
    return out;
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block);

  final LegalBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = VgType.bodyMd.copyWith(color: scheme.onSurface);
    final bold = body.copyWith(fontWeight: FontWeight.w600);
    Widget rich(TextStyle style) => Text.rich(
      TextSpan(style: style, children: LegalMarkdown.spans(block.text, bold)),
    );
    switch (block.kind) {
      case LegalBlockKind.title:
        return Padding(
          padding: const EdgeInsets.only(top: VgSpace.s2, bottom: VgSpace.s3),
          child: Semantics(
            header: true,
            child: Text(
              block.text,
              style: VgType.titleMd.copyWith(color: scheme.onSurface),
            ),
          ),
        );
      case LegalBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: VgSpace.s6, bottom: VgSpace.s2),
          child: Semantics(
            header: true,
            child: Text(
              block.text,
              style: VgType.titleSm.copyWith(color: scheme.onSurface),
            ),
          ),
        );
      case LegalBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: VgSpace.s3),
          child: rich(body),
        );
      case LegalBlockKind.bullet:
      case LegalBlockKind.numbered:
        return Padding(
          padding: const EdgeInsets.only(bottom: VgSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: VgSpace.s6,
                child: Text(
                  block.kind == LegalBlockKind.bullet
                      ? '•'
                      : '${block.number}.',
                  style: body,
                ),
              ),
              Expanded(child: rich(body)),
            ],
          ),
        );
    }
  }
}
