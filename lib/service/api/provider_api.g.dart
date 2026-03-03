// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providerApi)
final providerApiProvider = ProviderApiProvider._();

final class ProviderApiProvider
    extends $FunctionalProvider<ProviderApi, ProviderApi, ProviderApi>
    with $Provider<ProviderApi> {
  ProviderApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerApiHash();

  @$internal
  @override
  $ProviderElement<ProviderApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProviderApi create(Ref ref) {
    return providerApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProviderApi>(value),
    );
  }
}

String _$providerApiHash() => r'494b8194ab2bbb09674ab9084074625195d0a01a';
