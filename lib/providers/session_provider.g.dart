// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSessionNotifier)
final selectedSessionProvider = SelectedSessionNotifierProvider._();

final class SelectedSessionNotifierProvider
    extends $NotifierProvider<SelectedSessionNotifier, SelectedSessionState> {
  SelectedSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSessionNotifierHash();

  @$internal
  @override
  SelectedSessionNotifier create() => SelectedSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SelectedSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SelectedSessionState>(value),
    );
  }
}

String _$selectedSessionNotifierHash() =>
    r'c513ccffecbc1b7dbe683fa7bd0bf1b3a77ad55f';

abstract class _$SelectedSessionNotifier
    extends $Notifier<SelectedSessionState> {
  SelectedSessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SelectedSessionState, SelectedSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SelectedSessionState, SelectedSessionState>,
              SelectedSessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionMessagesNotifier)
final sessionMessagesProvider = SessionMessagesNotifierProvider._();

final class SessionMessagesNotifierProvider
    extends
        $AsyncNotifierProvider<
          SessionMessagesNotifier,
          List<MessageWithParts>
        > {
  SessionMessagesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionMessagesNotifierHash();

  @$internal
  @override
  SessionMessagesNotifier create() => SessionMessagesNotifier();
}

String _$sessionMessagesNotifierHash() =>
    r'd1bcb69d402c50aeb2a9fd3b5a219f20e850167b';

abstract class _$SessionMessagesNotifier
    extends $AsyncNotifier<List<MessageWithParts>> {
  FutureOr<List<MessageWithParts>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<MessageWithParts>>, List<MessageWithParts>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<MessageWithParts>>,
                List<MessageWithParts>
              >,
              AsyncValue<List<MessageWithParts>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
