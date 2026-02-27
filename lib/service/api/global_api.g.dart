// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalApi)
final globalApiProvider = GlobalApiProvider._();

final class GlobalApiProvider
    extends $FunctionalProvider<GlobalApi, GlobalApi, GlobalApi>
    with $Provider<GlobalApi> {
  GlobalApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalApiHash();

  @$internal
  @override
  $ProviderElement<GlobalApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GlobalApi create(Ref ref) {
    return globalApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalApi>(value),
    );
  }
}

String _$globalApiHash() => r'19145192d2bd8ac1692e99b618189694aa0bd6fd';
