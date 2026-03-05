// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServerConfigNotifier)
final serverConfigProvider = ServerConfigNotifierProvider._();

final class ServerConfigNotifierProvider
    extends $AsyncNotifierProvider<ServerConfigNotifier, ServerConfig> {
  ServerConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverConfigNotifierHash();

  @$internal
  @override
  ServerConfigNotifier create() => ServerConfigNotifier();
}

String _$serverConfigNotifierHash() =>
    r'dda3008a2cccceb542e89b32819e824d06674e71';

abstract class _$ServerConfigNotifier extends $AsyncNotifier<ServerConfig> {
  FutureOr<ServerConfig> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ServerConfig>, ServerConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerConfig>, ServerConfig>,
              AsyncValue<ServerConfig>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
