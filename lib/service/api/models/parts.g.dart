// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartTime _$PartTimeFromJson(Map<String, dynamic> json) => PartTime(
  start: (json['start'] as num).toInt(),
  end: (json['end'] as num?)?.toInt(),
);

Map<String, dynamic> _$PartTimeToJson(PartTime instance) => <String, dynamic>{
  'start': instance.start,
  'end': instance.end,
};

TextPart _$TextPartFromJson(Map<String, dynamic> json) => TextPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  text: json['text'] as String,
  synthetic: json['synthetic'] as bool?,
  ignored: json['ignored'] as bool?,
  time: json['time'] == null
      ? null
      : PartTime.fromJson(json['time'] as Map<String, dynamic>),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$TextPartToJson(TextPart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'text': instance.text,
  'synthetic': instance.synthetic,
  'ignored': instance.ignored,
  'time': instance.time,
  'metadata': instance.metadata,
};

ReasoningPart _$ReasoningPartFromJson(Map<String, dynamic> json) =>
    ReasoningPart(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      messageID: json['messageID'] as String,
      type: json['type'] as String,
      text: json['text'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReasoningPartToJson(ReasoningPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'text': instance.text,
      'metadata': instance.metadata,
      'time': instance.time,
    };

FilePartSourceText _$FilePartSourceTextFromJson(Map<String, dynamic> json) =>
    FilePartSourceText(
      value: json['value'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$FilePartSourceTextToJson(FilePartSourceText instance) =>
    <String, dynamic>{
      'value': instance.value,
      'start': instance.start,
      'end': instance.end,
    };

Range _$RangeFromJson(Map<String, dynamic> json) => Range(
  start: RangeStart.fromJson(json['start'] as Map<String, dynamic>),
  end: RangeEnd.fromJson(json['end'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RangeToJson(Range instance) => <String, dynamic>{
  'start': instance.start,
  'end': instance.end,
};

RangeStart _$RangeStartFromJson(Map<String, dynamic> json) => RangeStart(
  line: (json['line'] as num).toInt(),
  character: (json['character'] as num).toInt(),
);

Map<String, dynamic> _$RangeStartToJson(RangeStart instance) =>
    <String, dynamic>{'line': instance.line, 'character': instance.character};

RangeEnd _$RangeEndFromJson(Map<String, dynamic> json) => RangeEnd(
  line: (json['line'] as num).toInt(),
  character: (json['character'] as num).toInt(),
);

Map<String, dynamic> _$RangeEndToJson(RangeEnd instance) => <String, dynamic>{
  'line': instance.line,
  'character': instance.character,
};

FileSource _$FileSourceFromJson(Map<String, dynamic> json) => FileSource(
  text: FilePartSourceText.fromJson(json['text'] as Map<String, dynamic>),
  type: json['type'] as String,
  path: json['path'] as String,
);

Map<String, dynamic> _$FileSourceToJson(FileSource instance) =>
    <String, dynamic>{
      'text': instance.text,
      'type': instance.type,
      'path': instance.path,
    };

SymbolSource _$SymbolSourceFromJson(Map<String, dynamic> json) => SymbolSource(
  text: FilePartSourceText.fromJson(json['text'] as Map<String, dynamic>),
  type: json['type'] as String,
  path: json['path'] as String,
  range: Range.fromJson(json['range'] as Map<String, dynamic>),
  name: json['name'] as String,
  kind: (json['kind'] as num).toInt(),
);

Map<String, dynamic> _$SymbolSourceToJson(SymbolSource instance) =>
    <String, dynamic>{
      'text': instance.text,
      'type': instance.type,
      'path': instance.path,
      'range': instance.range,
      'name': instance.name,
      'kind': instance.kind,
    };

FilePart _$FilePartFromJson(Map<String, dynamic> json) => FilePart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  mime: json['mime'] as String,
  filename: json['filename'] as String?,
  url: json['url'] as String,
  source: json['source'],
);

Map<String, dynamic> _$FilePartToJson(FilePart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'mime': instance.mime,
  'filename': instance.filename,
  'url': instance.url,
  'source': instance.source,
};

ToolStatePending _$ToolStatePendingFromJson(Map<String, dynamic> json) =>
    ToolStatePending(
      status: json['status'] as String,
      input: json['input'] as Map<String, dynamic>,
      raw: json['raw'] as String,
    );

Map<String, dynamic> _$ToolStatePendingToJson(ToolStatePending instance) =>
    <String, dynamic>{
      'status': instance.status,
      'input': instance.input,
      'raw': instance.raw,
    };

ToolStateRunning _$ToolStateRunningFromJson(Map<String, dynamic> json) =>
    ToolStateRunning(
      status: json['status'] as String,
      input: json['input'] as Map<String, dynamic>,
      title: json['title'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolStateRunningToJson(ToolStateRunning instance) =>
    <String, dynamic>{
      'status': instance.status,
      'input': instance.input,
      'title': instance.title,
      'metadata': instance.metadata,
      'time': instance.time,
    };

ToolStateCompleted _$ToolStateCompletedFromJson(Map<String, dynamic> json) =>
    ToolStateCompleted(
      status: json['status'] as String,
      input: json['input'] as Map<String, dynamic>,
      output: json['output'] as String,
      title: json['title'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      time: ToolStateCompletedTime.fromJson(
        json['time'] as Map<String, dynamic>,
      ),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => FilePart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ToolStateCompletedToJson(ToolStateCompleted instance) =>
    <String, dynamic>{
      'status': instance.status,
      'input': instance.input,
      'output': instance.output,
      'title': instance.title,
      'metadata': instance.metadata,
      'time': instance.time,
      'attachments': instance.attachments,
    };

ToolStateCompletedTime _$ToolStateCompletedTimeFromJson(
  Map<String, dynamic> json,
) => ToolStateCompletedTime(
  start: (json['start'] as num).toInt(),
  end: (json['end'] as num).toInt(),
  compacted: (json['compacted'] as num?)?.toInt(),
);

Map<String, dynamic> _$ToolStateCompletedTimeToJson(
  ToolStateCompletedTime instance,
) => <String, dynamic>{
  'start': instance.start,
  'end': instance.end,
  'compacted': instance.compacted,
};

ToolStateError _$ToolStateErrorFromJson(Map<String, dynamic> json) =>
    ToolStateError(
      status: json['status'] as String,
      input: json['input'] as Map<String, dynamic>,
      error: json['error'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ToolStateErrorToJson(ToolStateError instance) =>
    <String, dynamic>{
      'status': instance.status,
      'input': instance.input,
      'error': instance.error,
      'metadata': instance.metadata,
      'time': instance.time,
    };

ToolPart _$ToolPartFromJson(Map<String, dynamic> json) => ToolPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  callID: json['callID'] as String,
  tool: json['tool'] as String,
  state: json['state'] as Object,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ToolPartToJson(ToolPart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'callID': instance.callID,
  'tool': instance.tool,
  'state': instance.state,
  'metadata': instance.metadata,
};

StepStartPart _$StepStartPartFromJson(Map<String, dynamic> json) =>
    StepStartPart(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      messageID: json['messageID'] as String,
      type: json['type'] as String,
      snapshot: json['snapshot'] as String?,
    );

Map<String, dynamic> _$StepStartPartToJson(StepStartPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'snapshot': instance.snapshot,
    };

StepFinishPart _$StepFinishPartFromJson(Map<String, dynamic> json) =>
    StepFinishPart(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      messageID: json['messageID'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      snapshot: json['snapshot'] as String?,
      cost: (json['cost'] as num).toInt(),
      tokens: MessageTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StepFinishPartToJson(StepFinishPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'reason': instance.reason,
      'snapshot': instance.snapshot,
      'cost': instance.cost,
      'tokens': instance.tokens,
    };

MessageTokens _$MessageTokensFromJson(Map<String, dynamic> json) =>
    MessageTokens(
      input: (json['input'] as num).toInt(),
      output: (json['output'] as num).toInt(),
      reasoning: (json['reasoning'] as num?)?.toInt(),
      cache: json['cache'] == null
          ? null
          : MessageCacheTokens.fromJson(json['cache'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageTokensToJson(MessageTokens instance) =>
    <String, dynamic>{
      'input': instance.input,
      'output': instance.output,
      'reasoning': instance.reasoning,
      'cache': instance.cache,
    };

MessageCacheTokens _$MessageCacheTokensFromJson(Map<String, dynamic> json) =>
    MessageCacheTokens(
      read: (json['read'] as num?)?.toInt(),
      write: (json['write'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageCacheTokensToJson(MessageCacheTokens instance) =>
    <String, dynamic>{'read': instance.read, 'write': instance.write};

SnapshotPart _$SnapshotPartFromJson(Map<String, dynamic> json) => SnapshotPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  snapshot: json['snapshot'] as String,
);

Map<String, dynamic> _$SnapshotPartToJson(SnapshotPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'snapshot': instance.snapshot,
    };

PatchPart _$PatchPartFromJson(Map<String, dynamic> json) => PatchPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  hash: json['hash'] as String,
  files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$PatchPartToJson(PatchPart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'hash': instance.hash,
  'files': instance.files,
};

AgentPart _$AgentPartFromJson(Map<String, dynamic> json) => AgentPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
  source: json['source'] == null
      ? null
      : AgentPartSource.fromJson(json['source'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AgentPartToJson(AgentPart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'name': instance.name,
  'source': instance.source,
};

AgentPartSource _$AgentPartSourceFromJson(Map<String, dynamic> json) =>
    AgentPartSource(
      value: json['value'] as String,
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$AgentPartSourceToJson(AgentPartSource instance) =>
    <String, dynamic>{
      'value': instance.value,
      'start': instance.start,
      'end': instance.end,
    };

RetryPart _$RetryPartFromJson(Map<String, dynamic> json) => RetryPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  attempt: (json['attempt'] as num).toInt(),
  error: json['error'] as Object,
  time: RetryPartTime.fromJson(json['time'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RetryPartToJson(RetryPart instance) => <String, dynamic>{
  'id': instance.id,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'type': instance.type,
  'attempt': instance.attempt,
  'error': instance.error,
  'time': instance.time,
};

RetryPartTime _$RetryPartTimeFromJson(Map<String, dynamic> json) =>
    RetryPartTime(created: (json['created'] as num).toInt());

Map<String, dynamic> _$RetryPartTimeToJson(RetryPartTime instance) =>
    <String, dynamic>{'created': instance.created};

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

CompactionPart _$CompactionPartFromJson(Map<String, dynamic> json) =>
    CompactionPart(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      messageID: json['messageID'] as String,
      type: json['type'] as String,
      auto: json['auto'] as bool,
    );

Map<String, dynamic> _$CompactionPartToJson(CompactionPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'auto': instance.auto,
    };

SubtaskPart _$SubtaskPartFromJson(Map<String, dynamic> json) => SubtaskPart(
  id: json['id'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  type: json['type'] as String,
  prompt: json['prompt'] as String,
  description: json['description'] as String,
  agent: json['agent'] as String,
);

Map<String, dynamic> _$SubtaskPartToJson(SubtaskPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'messageID': instance.messageID,
      'type': instance.type,
      'prompt': instance.prompt,
      'description': instance.description,
      'agent': instance.agent,
    };
