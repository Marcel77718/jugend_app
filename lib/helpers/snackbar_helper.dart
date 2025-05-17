// 📁 Datei: lib/helpers/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'package:jugend_app/helpers/app_constants.dart';

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
}

void showGreenSnackbar(BuildContext context, String message) {
  SnackbarHelper.success(context, message);
}

void showRedSnackbar(BuildContext context, String message) {
  SnackbarHelper.error(context, message);
}
