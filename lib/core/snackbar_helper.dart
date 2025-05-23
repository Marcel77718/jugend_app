// 📁 Datei: lib/core/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'package:jugend_app/core/app_texts.dart';

class SnackbarHelper {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  static void neutral(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.neutral),
    );
  }
}

void showGreenSnackbar(BuildContext context, String message) {
  SnackbarHelper.success(context, message);
}

void showRedSnackbar(BuildContext context, String message) {
  SnackbarHelper.error(context, message);
}

void showNeutralSnackbar(BuildContext context, String message) {
  SnackbarHelper.neutral(context, message);
}
