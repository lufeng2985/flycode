// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedProjectNotifier)
final selectedProjectProvider = SelectedProjectNotifierProvider._();

final class SelectedProjectNotifierProvider
    extends $AsyncNotifierProvider<SelectedProjectNotifier, Project?> {
  SelectedProjectNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedProjectProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedProjectNotifierHash();

  @$internal
  @override
  SelectedProjectNotifier create() => SelectedProjectNotifier();
}

String _$selectedProjectNotifierHash() =>
    r'b6016d712d0ad2c9d4b20aac5905786fe9a2a8be';

abstract class _$SelectedProjectNotifier extends $AsyncNotifier<Project?> {
  FutureOr<Project?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Project?>, Project?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Project?>, Project?>,
              AsyncValue<Project?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
