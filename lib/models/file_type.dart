enum FileType {
  image,
  video,
  other,
}

FileType getFileType(int fileType) {
  switch (fileType) {
    case 0:
      return FileType.image;
    case 1:
      return FileType.video;
    default:
      return FileType.other;
  }
}
