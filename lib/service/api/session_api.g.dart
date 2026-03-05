// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionApi)
final sessionApiProvider = SessionApiProvider._();

final class SessionApiProvider
    extends $FunctionalProvider<SessionApi, SessionApi, SessionApi>
    with $Provider<SessionApi> {
  SessionApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionApiHash();

  @$internal
  @override
  $ProviderElement<SessionApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionApi create(Ref ref) {
    return sessionApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionApi>(value),
    );
  }
}

String _$sessionApiHash() => r'537a6205534b6d5ce8a751ebdc4f0cfa9a97220e';

@ProviderFor(sessions)
final sessionsProvider = SessionsProvider._();

final class SessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>
        >
    with $FutureModifier<List<Session>>, $FutureProvider<List<Session>> {
  SessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Session>> create(Ref ref) {
    return sessions(ref);
  }
}

String _$sessionsHash() => r'22882f59078b5721ddf461c3e2899b3416c64e80';
