import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String sessionID;
  final String role;
  final String content;
  final int time;

  Message({
    required this.id,
    required this.sessionID,
    required this.role,
    required this.content,
    required this.time,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
