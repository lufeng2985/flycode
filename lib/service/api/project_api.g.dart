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
    extends
        $FunctionalProvider<
          AsyncValue<ProjectApi>,
          ProjectApi,
          FutureOr<ProjectApi>
        >
    with $FutureModifier<ProjectApi>, $FutureProvider<ProjectApi> {
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
  $FutureProviderElement<ProjectApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ProjectApi> create(Ref ref) {
    return projectApi(ref);
  }
}

String _$projectApiHash() => r'aa718dc825630bb1802dff1ca98b9d006ca7901b';

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

String _$projectsHash() => r'7ec3b7420577e64be695162262641ca5b920e6cb';
