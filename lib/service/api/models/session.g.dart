// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  id: json['id'] as String,
  title: json['title'] as String?,
  projectID: json['projectID'] as String?,
  parentID: json['parentID'] as String?,
  archived: json['archived'] as bool?,
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'projectID': instance.projectID,
  'parentID': instance.parentID,
  'archived': instance.archived,
  'updatedAt': instance.updatedAt,
};
