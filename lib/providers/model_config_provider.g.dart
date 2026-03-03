// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ModelConfigNotifier)
final modelConfigProvider = ModelConfigNotifierProvider._();

final class ModelConfigNotifierProvider
    extends
        $AsyncNotifierProvider<
          ModelConfigNotifier,
          Map<String, Map<String, bool>>
        > {
  ModelConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelConfigNotifierHash();

  @$internal
  @override
  ModelConfigNotifier create() => ModelConfigNotifier();
}

String _$modelConfigNotifierHash() =>
    r'36e96cf972e2f82d93bd229a507a38f748ba751a';

abstract class _$ModelConfigNotifier
    extends $AsyncNotifier<Map<String, Map<String, bool>>> {
  FutureOr<Map<String, Map<String, bool>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, Map<String, bool>>>,
              Map<String, Map<String, bool>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, Map<String, bool>>>,
                Map<String, Map<String, bool>>
              >,
              AsyncValue<Map<String, Map<String, bool>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
