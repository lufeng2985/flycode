// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  role: json['role'] as String,
  content: json['content'] as String,
  time: (json['time'] as num).toInt(),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'role': instance.role,
  'content': instance.content,
  'time': instance.time,
};
