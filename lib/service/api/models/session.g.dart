// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionTime _$SessionTimeFromJson(Map<String, dynamic> json) => SessionTime(
  created: (json['created'] as num).toInt(),
  updated: (json['updated'] as num).toInt(),
  compacting: (json['compacting'] as num?)?.toInt(),
  archived: (json['archived'] as num?)?.toInt(),
);

Map<String, dynamic> _$SessionTimeToJson(SessionTime instance) =>
    <String, dynamic>{
      'created': instance.created,
      'updated': instance.updated,
      'compacting': instance.compacting,
      'archived': instance.archived,
    };

FileDiff _$FileDiffFromJson(Map<String, dynamic> json) => FileDiff(
  file: json['file'] as String,
  before: json['before'] as String,
  after: json['after'] as String,
  additions: (json['additions'] as num).toInt(),
  deletions: (json['deletions'] as num).toInt(),
  status: json['status'] as String?,
);

Map<String, dynamic> _$FileDiffToJson(FileDiff instance) => <String, dynamic>{
  'file': instance.file,
  'before': instance.before,
  'after': instance.after,
  'additions': instance.additions,
  'deletions': instance.deletions,
  'status': instance.status,
};

SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    SessionSummary(
      additions: (json['additions'] as num).toInt(),
      deletions: (json['deletions'] as num).toInt(),
      files: (json['files'] as num).toInt(),
      diffs: (json['diffs'] as List<dynamic>?)
          ?.map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SessionSummaryToJson(SessionSummary instance) =>
    <String, dynamic>{
      'additions': instance.additions,
      'deletions': instance.deletions,
      'files': instance.files,
      'diffs': instance.diffs,
    };

SessionShare _$SessionShareFromJson(Map<String, dynamic> json) =>
    SessionShare(url: json['url'] as String);

Map<String, dynamic> _$SessionShareToJson(SessionShare instance) =>
    <String, dynamic>{'url': instance.url};

SessionRevert _$SessionRevertFromJson(Map<String, dynamic> json) =>
    SessionRevert(
      messageID: json['messageID'] as String,
      partID: json['partID'] as String?,
      snapshot: json['snapshot'] as String?,
      diff: json['diff'] as String?,
    );

Map<String, dynamic> _$SessionRevertToJson(SessionRevert instance) =>
    <String, dynamic>{
      'messageID': instance.messageID,
      'partID': instance.partID,
      'snapshot': instance.snapshot,
      'diff': instance.diff,
    };

PermissionRule _$PermissionRuleFromJson(Map<String, dynamic> json) =>
    PermissionRule(
      permission: json['permission'] as String,
      pattern: json['pattern'] as String,
      action: $enumDecode(_$PermissionActionEnumMap, json['action']),
    );

Map<String, dynamic> _$PermissionRuleToJson(PermissionRule instance) =>
    <String, dynamic>{
      'permission': instance.permission,
      'pattern': instance.pattern,
      'action': _$PermissionActionEnumMap[instance.action]!,
    };

const _$PermissionActionEnumMap = {
  PermissionAction.allow: 'allow',
  PermissionAction.deny: 'deny',
};

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  id: json['id'] as String,
  slug: json['slug'] as String,
  projectID: json['projectID'] as String,
  directory: json['directory'] as String,
  parentID: json['parentID'] as String?,
  summary: json['summary'] == null
      ? null
      : SessionSummary.fromJson(json['summary'] as Map<String, dynamic>),
  share: json['share'] == null
      ? null
      : SessionShare.fromJson(json['share'] as Map<String, dynamic>),
  title: json['title'] as String?,
  version: json['version'] as String,
  time: SessionTime.fromJson(json['time'] as Map<String, dynamic>),
  permission: (json['permission'] as List<dynamic>?)
      ?.map((e) => PermissionRule.fromJson(e as Map<String, dynamic>))
      .toList(),
  revert: json['revert'] == null
      ? null
      : SessionRevert.fromJson(json['revert'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'projectID': instance.projectID,
  'directory': instance.directory,
  'parentID': instance.parentID,
  'summary': instance.summary,
  'share': instance.share,
  'title': instance.title,
  'version': instance.version,
  'time': instance.time,
  'permission': instance.permission,
  'revert': instance.revert,
};
