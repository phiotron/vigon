import 'package:flutter/material.dart';

/// Icon đầu dòng cài đặt (`.lead.plain`): ô 40, màu chữ phụ (hoặc màu riêng).
/// Dùng chung cho màn Cài đặt và các nhóm tách riêng (nhắc, widget, sao lưu
/// tự động) để mọi dòng thẳng cột theo S08.
class SettingsLead extends StatelessWidget {
  const SettingsLead(this.icon, {super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    child: Center(child: Icon(icon, color: color)),
  );
}
