class DownloadTask {
  final int id;
  final String url;
  final String filename;
  int bytesDownloaded;
  int totalBytes;
  String status; // 'pending', 'downloading', 'paused', 'completed', 'error'
  String error;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.totalBytes,
    this.bytesDownloaded = 0,
    this.status = 'pending',
    this.error = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'status': status,
      'error': error,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'],
      url: map['url'],
      filename: map['filename'],
      bytesDownloaded: map['bytesDownloaded'],
      totalBytes: map['totalBytes'],
      status: map['status'],
      error: map['error'],
    );
  }
}
