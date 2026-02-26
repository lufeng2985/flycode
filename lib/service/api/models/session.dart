import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

@JsonSerializable()
class Session {
  final String id;
  final String? title;
  final String? projectID;
  final String? parentID;
  final bool? archived;
  final int? updatedAt;

  Session({
    required this.id,
    this.title,
    this.projectID,
    this.parentID,
    this.archived,
    this.updatedAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}
