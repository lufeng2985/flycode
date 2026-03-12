// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providerList)
final providerListProvider = ProviderListProvider._();

final class ProviderListProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProviderListResponse>,
          ProviderListResponse,
          FutureOr<ProviderListResponse>
        >
    with
        $FutureModifier<ProviderListResponse>,
        $FutureProvider<ProviderListResponse> {
  ProviderListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerListHash();

  @$internal
  @override
  $FutureProviderElement<ProviderListResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProviderListResponse> create(Ref ref) {
    return providerList(ref);
  }
}

String _$providerListHash() => r'71f71220df1d7858ff66e9e75e419e4ea0b3e9f8';
