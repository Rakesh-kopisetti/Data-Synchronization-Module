import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late bool isDeleted;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime updatedAt;

  @HiveField(6)
  late int syncStatus; // 0: pending, 1: synced, 2: failed

  @HiveField(7)
  late int operationType; // 0: create, 1: update, 2: delete

  Note({
    String id = '',
    required this.title,
    required this.content,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.pending,
    OperationType operationType = OperationType.create,
  })  : id = id.isEmpty ? '' : id,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        syncStatus = syncStatus.index,
        operationType = operationType.index;

  SyncStatus get syncStatusEnum => SyncStatus.values[syncStatus];
  OperationType get operationTypeEnum => OperationType.values[operationType];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Note fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      syncStatus: SyncStatus.synced,
      operationType: OperationType.update,
    );
  }

  static Note fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      syncStatus: SyncStatus.values[map['syncStatus'] as int? ?? 0],
      operationType: OperationType.values[map['operationType'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus,
      'operationType': operationType,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    OperationType? operationType,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? syncStatusEnum,
      operationType: operationType ?? operationTypeEnum,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ content.hashCode;

  @override
  String toString() =>
      'Note(id: $id, title: $title, isDeleted: $isDeleted, syncStatus: ${syncStatusEnum.label})';
}
