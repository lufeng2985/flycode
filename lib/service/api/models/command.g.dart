// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Command _$CommandFromJson(Map<String, dynamic> json) => Command(
  name: json['name'] as String,
  description: json['description'] as String?,
  agent: json['agent'] as String?,
  model: json['model'] as String?,
  mcp: json['mcp'] as bool?,
  template: json['template'] as String,
  subtask: json['subtask'] as bool?,
  hints: (json['hints'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$CommandToJson(Command instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'agent': instance.agent,
  'model': instance.model,
  'mcp': instance.mcp,
  'template': instance.template,
  'subtask': instance.subtask,
  'hints': instance.hints,
};
