// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectIcon _$ProjectIconFromJson(Map<String, dynamic> json) => ProjectIcon(
  url: json['url'] as String?,
  override: json['override'] as String?,
  color: json['color'] as String?,
);

Map<String, dynamic> _$ProjectIconToJson(ProjectIcon instance) =>
    <String, dynamic>{
      'url': instance.url,
      'override': instance.override,
      'color': instance.color,
    };

ProjectCommands _$ProjectCommandsFromJson(Map<String, dynamic> json) =>
    ProjectCommands(start: json['start'] as String?);

Map<String, dynamic> _$ProjectCommandsToJson(ProjectCommands instance) =>
    <String, dynamic>{'start': instance.start};

ProjectTime _$ProjectTimeFromJson(Map<String, dynamic> json) => ProjectTime(
  created: (json['created'] as num).toInt(),
  updated: (json['updated'] as num).toInt(),
  initialized: (json['initialized'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProjectTimeToJson(ProjectTime instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'initialized': instance.initialized,
    };

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String,
  worktree: json['worktree'] as String,
  vcs: json['vcs'] as String?,
  name: json['name'] as String?,
  icon: json['icon'] == null
      ? null
      : ProjectIcon.fromJson(json['icon'] as Map<String, dynamic>),
  commands: json['commands'] == null
      ? null
      : ProjectCommands.fromJson(json['commands'] as Map<String, dynamic>),
  time: ProjectTime.fromJson(json['time'] as Map<String, dynamic>),
  sandboxes: (json['sandboxes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'worktree': instance.worktree,
  'vcs': instance.vcs,
  'name': instance.name,
  'icon': instance.icon,
  'commands': instance.commands,
  'time': instance.time,
  'sandboxes': instance.sandboxes,
};
