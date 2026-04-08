// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(databaseHelper)
final databaseHelperProvider = DatabaseHelperProvider._();

final class DatabaseHelperProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  DatabaseHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseHelperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHelperHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return databaseHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$databaseHelperHash() => r'58556b75b05652cf1b077db4f63da63f60aa2fbc';

@ProviderFor(modelConfigDao)
final modelConfigDaoProvider = ModelConfigDaoProvider._();

final class ModelConfigDaoProvider
    extends
        $FunctionalProvider<
          AsyncValue<ModelConfigDao>,
          ModelConfigDao,
          FutureOr<ModelConfigDao>
        >
    with $FutureModifier<ModelConfigDao>, $FutureProvider<ModelConfigDao> {
  ModelConfigDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelConfigDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelConfigDaoHash();

  @$internal
  @override
  $FutureProviderElement<ModelConfigDao> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ModelConfigDao> create(Ref ref) {
    return modelConfigDao(ref);
  }
}

String _$modelConfigDaoHash() => r'd8ce37cf6dd726c2bd053b3aa9691d8af29c7b5b';

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
    r'c0e2660c9b2a0d05a7f6c42375e9e9ffe03e670b';

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
