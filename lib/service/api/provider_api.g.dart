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
    extends
        $FunctionalProvider<
          AsyncValue<ProviderApi>,
          ProviderApi,
          FutureOr<ProviderApi>
        >
    with $FutureModifier<ProviderApi>, $FutureProvider<ProviderApi> {
  ProviderApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerApiHash();

  @$internal
  @override
  $FutureProviderElement<ProviderApi> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProviderApi> create(Ref ref) {
    return providerApi(ref);
  }
}

String _$providerApiHash() => r'49aef454f4432b0a2841cea17bd74c7191ab4ec5';
