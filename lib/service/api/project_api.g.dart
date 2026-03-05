// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectApi)
final projectApiProvider = ProjectApiProvider._();

final class ProjectApiProvider
    extends $FunctionalProvider<ProjectApi, ProjectApi, ProjectApi>
    with $Provider<ProjectApi> {
  ProjectApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectApiHash();

  @$internal
  @override
  $ProviderElement<ProjectApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProjectApi create(Ref ref) {
    return projectApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectApi>(value),
    );
  }
}

String _$projectApiHash() => r'd3c5bbab00396d4868d1ee73983dd543b076786e';

@ProviderFor(projects)
final projectsProvider = ProjectsProvider._();

final class ProjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Project>>,
          List<Project>,
          FutureOr<List<Project>>
        >
    with $FutureModifier<List<Project>>, $FutureProvider<List<Project>> {
  ProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsHash();

  @$internal
  @override
  $FutureProviderElement<List<Project>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Project>> create(Ref ref) {
    return projects(ref);
  }
}

String _$projectsHash() => r'a58fba78610bbaacdfe56b143db2650e6283e588';
