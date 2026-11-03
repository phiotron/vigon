import 'package:flutter/material.dart';

/// ScaffoldMessenger chung, để thanh "Hoàn tác" còn hiện sau khi đóng màn sửa.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Hiện thanh "Đã xóa · Hoàn tác" trong 5 giây (AC-14).
void showUndoSnackBar({
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  rootMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        persist: false,
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}

void showMessage(String message) {
  rootMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
