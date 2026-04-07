// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalEventConnection)
final globalEventConnectionProvider = GlobalEventConnectionProvider._();

final class GlobalEventConnectionProvider
    extends
        $NotifierProvider<GlobalEventConnection, GlobalEventConnectionState> {
  GlobalEventConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalEventConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalEventConnectionHash();

  @$internal
  @override
  GlobalEventConnection create() => GlobalEventConnection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalEventConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalEventConnectionState>(value),
    );
  }
}

String _$globalEventConnectionHash() =>
    r'9fb054ce5a42b75f673f141a65d990b8a214fc02';

abstract class _$GlobalEventConnection
    extends $Notifier<GlobalEventConnectionState> {
  GlobalEventConnectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<GlobalEventConnectionState, GlobalEventConnectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                GlobalEventConnectionState,
                GlobalEventConnectionState
              >,
              GlobalEventConnectionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(GlobalEventListener)
final globalEventListenerProvider = GlobalEventListenerProvider._();

final class GlobalEventListenerProvider
    extends $StreamNotifierProvider<GlobalEventListener, GlobalEvent> {
  GlobalEventListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalEventListenerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalEventListenerHash();

  @$internal
  @override
  GlobalEventListener create() => GlobalEventListener();
}

String _$globalEventListenerHash() =>
    r'b47cc7705eaceac4a697d1392e3aa35d6cfd3962';

abstract class _$GlobalEventListener extends $StreamNotifier<GlobalEvent> {
  Stream<GlobalEvent> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GlobalEvent>, GlobalEvent>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GlobalEvent>, GlobalEvent>,
              AsyncValue<GlobalEvent>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
