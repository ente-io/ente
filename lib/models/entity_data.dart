import "package:photos/models/api/entity/type.dart";

class LocalEntityData {
  final String id;
  final EntityType type;
  final String data;
  final int ownerID;
  final int updatedAt;

  LocalEntityData({
    required this.id,
    required this.type,
    required this.data,
    required this.ownerID,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type.typeToString(),
      "data": data,
      "ownerID": ownerID,
      "updatedAt": updatedAt,
    };
  }

  factory LocalEntityData.fromJson(Map<String, dynamic> json) {
    return LocalEntityData(
      id: json["id"],
      type: typeFromString(json["type"]),
      data: json["data"],
      ownerID: int.parse(json["ownerID"]),
      updatedAt: int.parse(json["updatedAt"]),
    );
  }
}
