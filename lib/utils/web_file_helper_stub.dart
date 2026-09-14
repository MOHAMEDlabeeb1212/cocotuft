// Stub implementation of web file operations for non-web platforms.

void downloadExportFile({
  required String url,
  required String token,
  required Map<String, dynamic> payload,
  required Function(String error) onError,
}) {
  onError('File download is only supported on Flutter Web.');
}

void downloadTemplateFile({
  required String url,
  required String token,
  required Function(String error) onError,
}) {
  onError('Template download is only supported on Flutter Web.');
}

void uploadExcelFile({
  required String url,
  required String token,
  required Function(Map<String, dynamic> responseJson) onSuccess,
  required Function(String error) onError,
}) {
  onError('File upload is only supported on Flutter Web.');
}
