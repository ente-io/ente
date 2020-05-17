class Folder {
  final int folderID;
  final String name;
  final String owner;
  final String deviceFolder;
  final List<String> sharedWith;
  final int updateTimestamp;

  Folder(this.folderID, this.name, this.owner, this.deviceFolder,
      this.sharedWith, this.updateTimestamp);
}
