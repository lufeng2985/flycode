// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageTime _$MessageTimeFromJson(Map<String, dynamic> json) => MessageTime(
  created: (json['created'] as num).toInt(),
  completed: (json['completed'] as num?)?.toInt(),
);

Map<String, dynamic> _$MessageTimeToJson(MessageTime instance) =>
    <String, dynamic>{
      'created': instance.created,
      'completed': instance.completed,
    };

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  providerID: json['providerID'] as String,
  modelID: json['modelID'] as String,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'providerID': instance.providerID,
      'modelID': instance.modelID,
    };

MessagePath _$MessagePathFromJson(Map<String, dynamic> json) =>
    MessagePath(cwd: json['cwd'] as String, root: json['root'] as String);

Map<String, dynamic> _$MessagePathToJson(MessagePath instance) =>
    <String, dynamic>{'cwd': instance.cwd, 'root': instance.root};

MessageCacheTokens _$MessageCacheTokensFromJson(Map<String, dynamic> json) =>
    MessageCacheTokens(
      read: (json['read'] as num?)?.toInt(),
      write: (json['write'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageCacheTokensToJson(MessageCacheTokens instance) =>
    <String, dynamic>{'read': instance.read, 'write': instance.write};

MessageTokens _$MessageTokensFromJson(Map<String, dynamic> json) =>
    MessageTokens(
      input: (json['input'] as num?)?.toInt(),
      output: (json['output'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      reasoning: (json['reasoning'] as num?)?.toInt(),
      cache: json['cache'] == null
          ? null
          : MessageCacheTokens.fromJson(json['cache'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageTokensToJson(MessageTokens instance) =>
    <String, dynamic>{
      'input': instance.input,
      'output': instance.output,
      'total': instance.total,
      'reasoning': instance.reasoning,
      'cache': instance.cache,
    };

FileDiff _$FileDiffFromJson(Map<String, dynamic> json) => FileDiff(
  file: json['file'] as String,
  before: json['before'] as String,
  after: json['after'] as String,
  additions: (json['additions'] as num).toInt(),
  deletions: (json['deletions'] as num).toInt(),
);

Map<String, dynamic> _$FileDiffToJson(FileDiff instance) => <String, dynamic>{
  'file': instance.file,
  'before': instance.before,
  'after': instance.after,
  'additions': instance.additions,
  'deletions': instance.deletions,
};

UserMessageSummary _$UserMessageSummaryFromJson(Map<String, dynamic> json) =>
    UserMessageSummary(
      title: json['title'] as String?,
      body: json['body'] as String?,
      diffs: (json['diffs'] as List<dynamic>)
          .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserMessageSummaryToJson(UserMessageSummary instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      'diffs': instance.diffs,
    };

ProviderAuthError _$ProviderAuthErrorFromJson(Map<String, dynamic> json) =>
    ProviderAuthError(
      name: json['name'] as String,
      providerID: json['providerID'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ProviderAuthErrorToJson(ProviderAuthError instance) =>
    <String, dynamic>{
      'name': instance.name,
      'providerID': instance.providerID,
      'message': instance.message,
    };

UnknownError _$UnknownErrorFromJson(Map<String, dynamic> json) => UnknownError(
  name: json['name'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$UnknownErrorToJson(UnknownError instance) =>
    <String, dynamic>{'name': instance.name, 'message': instance.message};

MessageOutputLengthError _$MessageOutputLengthErrorFromJson(
  Map<String, dynamic> json,
) => MessageOutputLengthError(
  name: json['name'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$MessageOutputLengthErrorToJson(
  MessageOutputLengthError instance,
) => <String, dynamic>{'name': instance.name, 'data': instance.data};

MessageAbortedError _$MessageAbortedErrorFromJson(Map<String, dynamic> json) =>
    MessageAbortedError(
      name: json['name'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$MessageAbortedErrorToJson(
  MessageAbortedError instance,
) => <String, dynamic>{'name': instance.name, 'message': instance.message};

ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => ApiError(
  name: json['name'] as String,
  message: json['message'] as String,
  statusCode: (json['statusCode'] as num?)?.toInt(),
  isRetryable: json['isRetryable'] as bool,
  responseHeaders: (json['responseHeaders'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  responseBody: json['responseBody'] as String?,
);

Map<String, dynamic> _$ApiErrorToJson(ApiError instance) => <String, dynamic>{
  'name': instance.name,
  'message': instance.message,
  'statusCode': instance.statusCode,
  'isRetryable': instance.isRetryable,
  'responseHeaders': instance.responseHeaders,
  'responseBody': instance.responseBody,
};

UserMessage _$UserMessageFromJson(Map<String, dynamic> json) => UserMessage(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  role: json['role'] as String,
  time: MessageTime.fromJson(json['time'] as Map<String, dynamic>),
  summary: json['summary'] == null
      ? null
      : UserMessageSummary.fromJson(json['summary'] as Map<String, dynamic>),
  agent: json['agent'] as String,
  model: MessageModel.fromJson(json['model'] as Map<String, dynamic>),
  system: json['system'] as String?,
  tools: (json['tools'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
);

Map<String, dynamic> _$UserMessageToJson(UserMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'role': instance.role,
      'time': instance.time,
      'summary': instance.summary,
      'agent': instance.agent,
      'model': instance.model,
      'system': instance.system,
      'tools': instance.tools,
    };

AssistantMessage _$AssistantMessageFromJson(Map<String, dynamic> json) =>
    AssistantMessage(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      role: json['role'] as String,
      time: MessageTime.fromJson(json['time'] as Map<String, dynamic>),
      error: json['error'],
      parentID: json['parentID'] as String,
      modelID: json['modelID'] as String,
      providerID: json['providerID'] as String,
      mode: json['mode'] as String,
      path: MessagePath.fromJson(json['path'] as Map<String, dynamic>),
      summary: json['summary'] as bool?,
      cost: (json['cost'] as num?)?.toDouble(),
      tokens: MessageTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      finish: json['finish'] as String?,
    );

Map<String, dynamic> _$AssistantMessageToJson(AssistantMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'role': instance.role,
      'time': instance.time,
      'error': instance.error,
      'parentID': instance.parentID,
      'modelID': instance.modelID,
      'providerID': instance.providerID,
      'mode': instance.mode,
      'path': instance.path,
      'summary': instance.summary,
      'cost': instance.cost,
      'tokens': instance.tokens,
      'finish': instance.finish,
    };

MessageWithParts _$MessageWithPartsFromJson(Map<String, dynamic> json) =>
    MessageWithParts(
      info: json['info'] as Object,
      parts: (json['parts'] as List<dynamic>).map((e) => e as Object).toList(),
    );

Map<String, dynamic> _$MessageWithPartsToJson(MessageWithParts instance) =>
    <String, dynamic>{'info': instance.info, 'parts': instance.parts};
