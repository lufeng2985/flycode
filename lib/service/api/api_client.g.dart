// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApiClient>,
          ApiClient,
          FutureOr<ApiClient>
        >
    with $FutureModifier<ApiClient>, $FutureProvider<ApiClient> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $FutureProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ApiClient> create(Ref ref) {
    return apiClient(ref);
  }
}

String _$apiClientHash() => r'3e1a7a5324c6cc0e10362f17925ded4982b2c635';
