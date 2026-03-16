import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

@JsonSerializable()
class ProjectIcon {
  final String? url;
  final String? override;
  final String? color;

  ProjectIcon({this.url, this.override, this.color});

  factory ProjectIcon.fromJson(Map<String, dynamic> json) => ProjectIcon(
    url: json['url'] as String?,
    override: json['override'] as String?,
    color: json['color'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (url != null) 'url': url,
    if (override != null) 'override': override,
    if (color != null) 'color': color,
  };
}

@JsonSerializable()
class ProjectCommands {
  final String? start;

  ProjectCommands({this.start});

  factory ProjectCommands.fromJson(Map<String, dynamic> json) =>
      ProjectCommands(start: json['start'] as String?);

  Map<String, dynamic> toJson() => {if (start != null) 'start': start};
}

@JsonSerializable()
class ProjectTime {
  final int created;
  final int updated;
  final int? initialized;

  ProjectTime({required this.created, required this.updated, this.initialized});

  factory ProjectTime.fromJson(Map<String, dynamic> json) => ProjectTime(
    created: (json['created'] as num).toInt(),
    updated: (json['updated'] as num).toInt(),
    initialized: (json['initialized'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'created': created,
    'updated': updated,
    if (initialized != null) 'initialized': initialized,
  };
}

@JsonSerializable()
class Project {
  final String id;
  final String worktree;
  final String? vcs;
  final String? name;
  final ProjectIcon? icon;
  final ProjectCommands? commands;
  final ProjectTime time;
  final List<String> sandboxes;

  Project({
    required this.id,
    required this.worktree,
    this.vcs,
    this.name,
    this.icon,
    this.commands,
    required this.time,
    required this.sandboxes,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
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
    sandboxes:
        (json['sandboxes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );

  factory Project.fromDirectory(String directory, {int? updatedAt}) {
    final parts = directory.replaceAll('\\', '/').split('/');
    final name = parts.lastWhere((p) => p.isNotEmpty, orElse: () => 'root');
    final id = Uri.encodeComponent(directory).replaceAll('%', '_');
    final now = DateTime.now().millisecondsSinceEpoch;

    return Project(
      id: id,
      worktree: directory,
      name: name,
      time: ProjectTime(created: now, updated: updatedAt ?? now),
      sandboxes: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'worktree': worktree,
    if (vcs != null) 'vcs': vcs,
    if (name != null) 'name': name,
    if (icon != null) 'icon': icon!.toJson(),
    if (commands != null) 'commands': commands!.toJson(),
    'time': time.toJson(),
    'sandboxes': sandboxes,
  };
}
