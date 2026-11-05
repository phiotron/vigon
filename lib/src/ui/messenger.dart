import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.g.dart';

/// ScaffoldMessenger chung, để thanh "Hoàn tác" còn hiện sau khi đóng màn sửa.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Thời gian hiện thanh thông báo: chỉ chữ 4 s, có nút 5 s (Hoàn tác), loại
/// dài cần đọc kỹ 10 s (Feedback.html "Stacked, 10 s").
abstract final class SnackDuration {
  static const short = Duration(seconds: 4);
  static const action = Duration(seconds: 5);
  static const long = Duration(seconds: 10);
}

/// Hiện thanh "Đã xóa · Hoàn tác" trong 5 giây (AC-14).
void showUndoSnackBar({
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) => showVgSnackBar(message, actionLabel: undoLabel, onAction: onUndo);

/// Thanh thông báo chỉ có chữ, 4 giây ("Đã sao lưu").
void showMessage(String message) => showVgSnackBar(message);

/// Thanh thông báo theo `.vg-snack` v2 (Feedback.html, CHANGELOG "Changed"):
/// 1–3 dòng (cao lên theo chữ, không cắt), nút hành động bên phải; chữ dài
/// thì xếp chồng, nút xuống dưới chữ. Có nút thì có vạch thời gian co dần ở
/// đáy. Luôn nằm trên vùng bọc bằng [SnackBarClearance] (− / +, bàn phím số)
/// và trên bàn phím hệ thống.
///
/// [duration] mặc định: không nút 4 s, có nút 5 s; [long] = 10 s.
void showVgSnackBar(
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
  bool long = false,
}) {
  final messenger = rootMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      buildVgSnackBar(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        long: long,
        clearance: SnackBarClearance.current(),
      ),
    );
}

/// [SnackBar] của [showVgSnackBar], dùng riêng khi cần
/// `ScaffoldMessenger.of(context)` thay cho messenger chung. [clearance] là
/// khoảng phải chừa ở đáy (xem [SnackBarClearance.current]).
SnackBar buildVgSnackBar(
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
  bool long = false,
  double clearance = 0,
}) {
  assert((actionLabel == null) == (onAction == null));
  final time =
      duration ??
      (long
          ? SnackDuration.long
          : actionLabel != null
          ? SnackDuration.action
          : SnackDuration.short);
  return SnackBar(
    padding: EdgeInsets.zero,
    duration: time,
    // Không giữ lại khi có nút: hết giờ thì tự đóng như bản vẽ (AC-14).
    persist: false,
    margin: clearance > 0
        ? EdgeInsets.fromLTRB(
            VgSpace.s3,
            VgSpace.s1,
            VgSpace.s3,
            clearance + VgSpace.s2,
          )
        : null,
    content: VgSnackContent(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: time,
    ),
  );
}

/// Nội dung thanh thông báo: chữ body-sm `inverse-ink`, nút label-md 600 màu
/// `inverse-primary` cao 40 (vùng chạm 48), vạch thời gian 2 dp khi có nút.
class VgSnackContent extends StatefulWidget {
  const VgSnackContent({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.duration = SnackDuration.action,
    this.showTimer,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  /// Mặc định hiện vạch thời gian khi có nút hành động.
  final bool? showTimer;

  @override
  State<VgSnackContent> createState() => _VgSnackContentState();
}

class _VgSnackContentState extends State<VgSnackContent> {
  /// Bước co của vạch thời gian. Co bằng [Timer] từng bước thay vì
  /// AnimationController: vạch 2 dp không cần 60 khung/giây, và không giữ
  /// khung hình liên tục (pumpAndSettle trong test không chạy hết thời gian
  /// hiện của thanh).
  static const _step = Duration(milliseconds: 50);

  Timer? _ticker;
  var _elapsed = Duration.zero;

  bool get _hasTimer => widget.showTimer ?? widget.actionLabel != null;

  /// Phần vạch còn lại, 1 → 0.
  double get _left =>
      1 -
      (_elapsed.inMicroseconds / widget.duration.inMicroseconds).clamp(0, 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Giảm chuyển động: vạch đứng yên (motion.md).
    final run = _hasTimer && !VgMotion.reduced(context);
    if (run && _ticker == null) {
      _ticker = Timer.periodic(_step, (t) {
        setState(() => _elapsed += _step);
        if (_elapsed >= widget.duration) t.cancel();
      });
    } else if (!run) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _act() {
    ScaffoldMessenger.maybeOf(context)
        ?.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    widget.onAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    // ColorScheme (không cần ViGonColors) để chạy được cả dưới theme lạ.
    final p = Theme.of(context).colorScheme;
    final textStyle = VgType.bodySm.copyWith(color: p.onInverseSurface);
    final actionStyle = VgType.labelMd.copyWith(
      color: p.inversePrimary,
      fontWeight: FontWeight.w600,
    );
    final label = widget.actionLabel;
    final text = Text(widget.message, style: textStyle);
    final action = label == null
        ? null
        : TextButton(
            onPressed: _act,
            style: TextButton.styleFrom(
              foregroundColor: p.inversePrimary,
              textStyle: actionStyle,
              minimumSize: const Size(VgSize.tapMin, 40),
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s3),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(label, softWrap: false),
          );

    final body = LayoutBuilder(
      builder: (context, constraints) {
        if (action == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: text,
          );
        }
        // Xếp chồng khi chữ + nút không vừa một dòng.
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        double width(String s, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: s, style: style),
            textScaler: scaler,
            textDirection: dir,
            maxLines: 1,
          )..layout();
          final w = painter.width;
          painter.dispose();
          return w;
        }

        final need =
            width(widget.message, textStyle) +
            VgSpace.s2 +
            math.max(
              VgSize.tapMin,
              width(label!, actionStyle) + 2 * VgSpace.s3,
            );
        if (need <= constraints.maxWidth) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: text,
                ),
              ),
              const SizedBox(width: VgSpace.s2),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, VgSpace.s2, VgSpace.s2, 0),
              child: text,
            ),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        );
      },
    );

    return Stack(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VgSize.tapMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              VgSpace.s4,
              VgSpace.s1,
              VgSpace.s2,
              VgSpace.s1,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: body,
            ),
          ),
        ),
        if (_hasTimer)
          Positioned(
            left: VgSpace.s2,
            right: VgSpace.s2,
            bottom: 0,
            height: 2,
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: ColoredBox(
                  key: const ValueKey('snack-timer'),
                  color: p.onInverseSurface.withValues(alpha: 0.25),
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: _left,
                    child: ColoredBox(color: p.inversePrimary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bọc vùng ở đáy màn mà thanh thông báo không được che: hàng − / + ở màn
/// chính, bàn phím số và nút Lưu ở màn ghi khoản (CHANGELOG: "The snackbar
/// always sits above − / + and the keypad"). Chỉ tính vùng thuộc route đang
/// hiện, nên màn chính nằm dưới màn khác không đẩy thanh lên.
class SnackBarClearance extends StatefulWidget {
  const SnackBarClearance({super.key, required this.child});

  final Widget child;

  /// Khoảng từ mép trên vùng được bọc (cao nhất, route đang hiện) tới đáy
  /// vùng đặt thanh thông báo (trên thanh điều hướng hệ thống / bàn phím); 0
  /// khi không có vùng nào.
  static double current() {
    var best = 0.0;
    for (final s in _SnackBarClearanceState._mounted) {
      best = math.max(best, s._clearance());
    }
    return best;
  }

  @override
  State<SnackBarClearance> createState() => _SnackBarClearanceState();
}

class _SnackBarClearanceState extends State<SnackBarClearance> {
  static final _mounted = <_SnackBarClearanceState>{};

  ModalRoute<Object?>? _route;

  @override
  void initState() {
    super.initState();
    _mounted.add(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _mounted.remove(this);
    super.dispose();
  }

  double _clearance() {
    if (!mounted || (_route != null && !_route!.isCurrent)) return 0;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return 0;
    final media = MediaQuery.of(context);
    // Đáy vùng đặt thanh thông báo nổi của Scaffold: trên thanh điều hướng
    // hệ thống, hoặc trên bàn phím khi bàn phím mở.
    final base =
        media.size.height -
        math.max(media.viewPadding.bottom, media.viewInsets.bottom);
    return math.max(0, base - box.localToGlobal(Offset.zero).dy);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
