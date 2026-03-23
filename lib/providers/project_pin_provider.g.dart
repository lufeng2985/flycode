// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_pin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProjectPins)
final projectPinsProvider = ProjectPinsProvider._();

final class ProjectPinsProvider
    extends $AsyncNotifierProvider<ProjectPins, Map<String, int>> {
  ProjectPinsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectPinsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectPinsHash();

  @$internal
  @override
  ProjectPins create() => ProjectPins();
}

String _$projectPinsHash() => r'71440e4e5573623ed9aaabe8b7a8e52de66d6b97';

abstract class _$ProjectPins extends $AsyncNotifier<Map<String, int>> {
  FutureOr<Map<String, int>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, int>>, Map<String, int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, int>>, Map<String, int>>,
              AsyncValue<Map<String, int>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
