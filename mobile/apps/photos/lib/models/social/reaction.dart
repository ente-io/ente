class Reaction {
  final String id;
  final int collectionID;
  final int? fileID;
  final String? commentID;
  final String data;
  final bool isDeleted;
  final int userID;
  final String? anonUserID;
  final int createdAt;
  final int updatedAt;

  Reaction({
    required this.id,
    required this.collectionID,
    this.fileID,
    this.commentID,
    required this.data,
    this.isDeleted = false,
    required this.userID,
    this.anonUserID,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAnonymous => userID <= 0;

  bool get isOnFile => fileID != null && commentID == null;

  bool get isOnComment => commentID != null;

  bool get isOnCollection => fileID == null && commentID == null;

  Reaction copyWith({
    String? id,
    int? collectionID,
    int? fileID,
    String? commentID,
    String? data,
    bool? isDeleted,
    int? userID,
    String? anonUserID,
    int? createdAt,
    int? updatedAt,
  }) {
    return Reaction(
      id: id ?? this.id,
      collectionID: collectionID ?? this.collectionID,
      fileID: fileID ?? this.fileID,
      commentID: commentID ?? this.commentID,
      data: data ?? this.data,
      isDeleted: isDeleted ?? this.isDeleted,
      userID: userID ?? this.userID,
      anonUserID: anonUserID ?? this.anonUserID,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collectionID': collectionID,
      'fileID': fileID,
      'commentID': commentID,
      'data': data,
      'isDeleted': isDeleted,
      'userID': userID,
      'anonUserID': anonUserID,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as String,
      collectionID: map['collectionID'] as int,
      fileID: map['fileID'] as int?,
      commentID: map['commentID'] as String?,
      data: map['data'] as String,
      isDeleted: map['isDeleted'] as bool? ?? false,
      userID: map['userID'] as int,
      anonUserID: map['anonUserID'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
}
