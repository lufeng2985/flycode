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

@ProviderFor(sessionDiff)
final sessionDiffProvider = SessionDiffFamily._();

final class SessionDiffProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileDiff>>,
          List<FileDiff>,
          FutureOr<List<FileDiff>>
        >
    with $FutureModifier<List<FileDiff>>, $FutureProvider<List<FileDiff>> {
  SessionDiffProvider._({
    required SessionDiffFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionDiffProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionDiffHash();

  @override
  String toString() {
    return r'sessionDiffProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FileDiff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileDiff>> create(Ref ref) {
    final argument = this.argument as String;
    return sessionDiff(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionDiffProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionDiffHash() => r'dc5fdb3610ea7e29f9a3739f3f02e005dc704b5c';

final class SessionDiffFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FileDiff>>, String> {
  SessionDiffFamily._()
    : super(
        retry: null,
        name: r'sessionDiffProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionDiffProvider call(String sessionID) =>
      SessionDiffProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionDiffProvider';
}
