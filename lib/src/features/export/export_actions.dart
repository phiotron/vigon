import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/export_data.dart';
import '../../data/period.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../home/range_calendar.dart';
import 'export_pdf.dart';
import 'export_xlsx.dart';

/// Định dạng file xuất (F-40).
enum ExportFormat { xlsx, pdf }

const _regularFont = 'assets/fonts/BeVietnamPro-Regular.ttf';
const _boldFont = 'assets/fonts/BeVietnamPro-Bold.ttf';

/// Bảng "Xuất khoảng nào" (AC-116): kỳ đang xem (ghi tên kỳ) hoặc khoảng tùy
/// chọn (mở lịch khoảng như Khoảng tùy chọn). Trả về phạm vi, null khi đóng.
Future<Period?> pickExportRange(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final current = ref.read(periodProvider);
  final picked = await showChoiceSheet<bool>(
    context,
    title: l.exportScopeTitle,
    options: [
      ChoiceOption(
        false,
        '${l.exportScopeCurrent} · ${periodTitle(context, current)}',
        icon: Symbols.calendar_month_rounded,
      ),
      ChoiceOption(true, l.exportScopeCustom, icon: Symbols.date_range_rounded),
    ],
    selected: false,
  );
  if (picked == null || !context.mounted) return null;
  if (!picked.$1) return current;
  final now = ref.read(clockProvider)();
  final range = await showRangeCalendar(
    context,
    initialStart: current.type == PeriodType.all ? null : current.start,
    initialEnd: current.type == PeriodType.all ? null : current.end,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 10, 12, 31),
    today: now,
    weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
  );
  return range == null ? null : Period.custom(range.start, range.end);
}

String _stamp(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
    '-${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';

/// Dựng file trong isolate riêng để vòng xoay "Đang tạo file…" không đứng
/// (AC-118: 1.000 khoản ≤ 10 giây trên Galaxy A13).
Future<Uint8List> _build(
  ExportFormat format,
  ExportData data,
  AppLocalizations l,
  String title,
  ExportFonts? fonts,
) => Isolate.run(() async {
  switch (format) {
    case ExportFormat.xlsx:
      return buildExportXlsx(data, l);
    case ExportFormat.pdf:
      await initializeDateFormatting(l.localeName);
      return buildExportPdf(data, l, periodTitle: title, fonts: fonts!);
  }
});

/// Cài đặt → Dữ liệu → "Xuất Excel" / "Xuất PDF" (AC-116): chọn phạm vi, dựng
/// file, rồi mở bảng chia sẻ của hệ điều hành (như AC-28; không xin quyền bộ
/// nhớ). File ghi vào thư mục tạm của app.
Future<void> exportReportFile(
  BuildContext context,
  WidgetRef ref,
  ExportFormat format,
) async {
  final l = AppLocalizations.of(context);
  final range = await pickExportRange(context, ref);
  if (range == null || !context.mounted) return;
  final title = periodTitle(context, range);
  final navigator = Navigator.of(context, rootNavigator: true);
  var dialogOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const _ExportWorkingDialog(),
  ).whenComplete(() => dialogOpen = false);
  Uint8List bytes;
  try {
    final service = await ref.read(currencyServiceProvider.future);
    final data = await loadExportData(
      ref.read(databaseProvider),
      range,
      service,
    );
    final fonts = format == ExportFormat.pdf
        ? ExportFonts(
            regular: (await rootBundle.load(_regularFont)).buffer.asUint8List(),
            bold: (await rootBundle.load(_boldFont)).buffer.asUint8List(),
          )
        : null;
    bytes = await _build(format, data, l, title, fonts);
  } catch (_) {
    if (dialogOpen) navigator.pop();
    showMessage(l.exportFailed);
    return;
  }
  if (dialogOpen) navigator.pop();
  final (ext, mime) = switch (format) {
    ExportFormat.xlsx => (
      'xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
    ExportFormat.pdf => ('pdf', 'application/pdf'),
  };
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/vigon-${_stamp(ref.read(clockProvider)())}.$ext',
  );
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: mime)]),
  );
}

/// Hộp "Đang tạo file…" không đóng được khi đang dựng file.
class _ExportWorkingDialog extends StatelessWidget {
  const _ExportWorkingDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: VgSpace.s4),
            Expanded(
              child: Semantics(liveRegion: true, child: Text(l.exportWorking)),
            ),
          ],
        ),
      ),
    );
  }
}
