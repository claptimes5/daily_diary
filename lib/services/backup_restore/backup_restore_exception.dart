class BackupRestoreException implements Exception {
  final String previousExceptionMessage;

  BackupRestoreException(this.previousExceptionMessage);

  String get message => 'Backup or restore failed: ' + previousExceptionMessage;

  @override
  String toString() {
    return message;
  }
}
