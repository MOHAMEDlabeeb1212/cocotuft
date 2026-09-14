// Web implementation of file operations using dart:html.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

void downloadExportFile({
  required String url,
  required String token,
  required Map<String, dynamic> payload,
  required Function(String error) onError,
}) {
  html.HttpRequest.request(
    url,
    method: 'POST',
    requestHeaders: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    sendData: jsonEncode(payload),
    responseType: 'blob',
  ).then((xhr) {
    final blob = xhr.response as html.Blob;
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: objectUrl)
      ..setAttribute('download', 'Cocotuft_Production_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx')
      ..click();
    html.Url.revokeObjectUrl(objectUrl);
  }).catchError((err) {
    onError(err.toString());
  });
}

void downloadTemplateFile({
  required String url,
  required String token,
  required Function(String error) onError,
}) {
  html.HttpRequest.request(
    url,
    method: 'GET',
    requestHeaders: {
      'Authorization': 'Bearer $token',
    },
    responseType: 'blob',
  ).then((xhr) {
    final blob = xhr.response as html.Blob;
    final objectUrl = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: objectUrl)
      ..setAttribute('download', 'Cocotuft_Production_Import_Template.xlsx')
      ..click();
    html.Url.revokeObjectUrl(objectUrl);
  }).catchError((err) {
    onError(err.toString());
  });
}

void uploadExcelFile({
  required String url,
  required String token,
  required Function(Map<String, dynamic> responseJson) onSuccess,
  required Function(String error) onError,
}) {
  final uploadInput = html.FileUploadInputElement()..accept = '.xlsx, .xls';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) async {
        final bytes = reader.result as List<int>;

        final formData = html.FormData();
        formData.appendBlob('file', html.Blob([bytes]), file.name);

        final xhr = html.HttpRequest();
        xhr.open('POST', url);
        xhr.setRequestHeader('Authorization', 'Bearer $token');
        xhr.onLoad.listen((_) {
          if (xhr.status == 200) {
            final jsonRes = jsonDecode(xhr.responseText!);
            onSuccess(jsonRes as Map<String, dynamic>);
          } else {
            onError('File upload failed (${xhr.status})');
          }
        });
        xhr.onError.listen((err) {
          onError('Upload network error');
        });
        xhr.send(formData);
      });
    }
  });
}
