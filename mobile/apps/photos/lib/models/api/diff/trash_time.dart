class TrashTime {
  int createdAt;
  int updatedAt;
  int deleteBy;
  TrashTime({
    required this.createdAt,
    required this.updatedAt,
    required this.deleteBy,
  });
  TrashTime.fromMap(Map<String, dynamic> map)
      : createdAt = map["createdAt"] as int,
        updatedAt = map["updatedAt"] as int,
        deleteBy = map["deleteBy"] as int;
  Map<String, dynamic> toMap() {
    return {
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "deleteBy": deleteBy,
    };
  }
}
