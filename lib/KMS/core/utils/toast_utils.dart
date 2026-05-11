import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ToastType { success, error, info, warning }

class ToastUtils {
  static void show(String message, {ToastType type = ToastType.info}) {
    Color backgroundColor;

    switch (type) {
      case ToastType.success:
        backgroundColor = Colors.green;
        break;
      case ToastType.error:
        backgroundColor = Colors.red;
        break;
      case ToastType.warning:
        backgroundColor = Colors.amber;
        break;
      case ToastType.info:
        backgroundColor = Colors.blueAccent;
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showSuccess(String message) {
    show(message, type: ToastType.success);
  }

  static void showError(String message) {
    show(message, type: ToastType.error);
  }

  static void showInfo(String message) {
    show(message, type: ToastType.info);
  }

  static void showWarning(String message) {
    show(message, type: ToastType.warning);
  }
}
