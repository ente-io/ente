class Comment {
  final String id;
  final int collectionID;
  final int? fileID;
  final String data;
  final String? parentCommentID;
  final int? parentCommentUserID;
  final bool isDeleted;
  final int userID;
  final String? anonUserID;
  final int createdAt;
  final int updatedAt;

  Comment({
    required this.id,
    required this.collectionID,
    this.fileID,
    required this.data,
    this.parentCommentID,
    this.parentCommentUserID,
    this.isDeleted = false,
    required this.userID,
    this.anonUserID,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAnonymous => userID <= 0;

  bool get isReply => parentCommentID != null;

  bool get isOnFile => fileID != null;

  Comment copyWith({
    String? id,
    int? collectionID,
    int? fileID,
    String? data,
    String? parentCommentID,
    int? parentCommentUserID,
    bool? isDeleted,
    int? userID,
    String? anonUserID,
    int? createdAt,
    int? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      collectionID: collectionID ?? this.collectionID,
      fileID: fileID ?? this.fileID,
      data: data ?? this.data,
      parentCommentID: parentCommentID ?? this.parentCommentID,
      parentCommentUserID: parentCommentUserID ?? this.parentCommentUserID,
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
      'data': data,
      'parentCommentID': parentCommentID,
      'parentCommentUserID': parentCommentUserID,
      'isDeleted': isDeleted,
      'userID': userID,
      'anonUserID': anonUserID,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      collectionID: map['collectionID'] as int,
      fileID: map['fileID'] as int?,
      data: map['data'] as String,
      parentCommentID: map['parentCommentID'] as String?,
      parentCommentUserID: map['parentCommentUserID'] as int?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      userID: map['userID'] as int,
      anonUserID: map['anonUserID'] as String?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
}
