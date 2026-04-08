// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingPermissions)
final pendingPermissionsProvider = PendingPermissionsProvider._();

final class PendingPermissionsProvider
    extends
        $AsyncNotifierProvider<PendingPermissions, List<PermissionRequest>> {
  PendingPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingPermissionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingPermissionsHash();

  @$internal
  @override
  PendingPermissions create() => PendingPermissions();
}

String _$pendingPermissionsHash() =>
    r'63c678d12918b3db6e6fe25333729e61303e35bf';

abstract class _$PendingPermissions
    extends $AsyncNotifier<List<PermissionRequest>> {
  FutureOr<List<PermissionRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PermissionRequest>>,
              List<PermissionRequest>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PermissionRequest>>,
                List<PermissionRequest>
              >,
              AsyncValue<List<PermissionRequest>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(allSessions)
final allSessionsProvider = AllSessionsProvider._();

final class AllSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>
        >
    with $FutureModifier<List<Session>>, $FutureProvider<List<Session>> {
  AllSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allSessionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allSessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Session>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Session>> create(Ref ref) {
    return allSessions(ref);
  }
}

String _$allSessionsHash() => r'7a8ae3843bf1079ca88c2b72495e7cfe85e52206';

@ProviderFor(currentSessionPermissionRequest)
final currentSessionPermissionRequestProvider =
    CurrentSessionPermissionRequestFamily._();

final class CurrentSessionPermissionRequestProvider
    extends
        $FunctionalProvider<
          PermissionRequest?,
          PermissionRequest?,
          PermissionRequest?
        >
    with $Provider<PermissionRequest?> {
  CurrentSessionPermissionRequestProvider._({
    required CurrentSessionPermissionRequestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentSessionPermissionRequestProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentSessionPermissionRequestHash();

  @override
  String toString() {
    return r'currentSessionPermissionRequestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PermissionRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PermissionRequest? create(Ref ref) {
    final argument = this.argument as String;
    return currentSessionPermissionRequest(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionRequest?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentSessionPermissionRequestProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentSessionPermissionRequestHash() =>
    r'08e2a9040fc3c44d6b88c00c3d56bb19bf911e4f';

final class CurrentSessionPermissionRequestFamily extends $Family
    with $FunctionalFamilyOverride<PermissionRequest?, String> {
  CurrentSessionPermissionRequestFamily._()
    : super(
        retry: null,
        name: r'currentSessionPermissionRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CurrentSessionPermissionRequestProvider call(String sessionID) =>
      CurrentSessionPermissionRequestProvider._(
        argument: sessionID,
        from: this,
      );

  @override
  String toString() => r'currentSessionPermissionRequestProvider';
}

@ProviderFor(currentSessionHasPermissionBlock)
final currentSessionHasPermissionBlockProvider =
    CurrentSessionHasPermissionBlockFamily._();

final class CurrentSessionHasPermissionBlockProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  CurrentSessionHasPermissionBlockProvider._({
    required CurrentSessionHasPermissionBlockFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentSessionHasPermissionBlockProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentSessionHasPermissionBlockHash();

  @override
  String toString() {
    return r'currentSessionHasPermissionBlockProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return currentSessionHasPermissionBlock(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentSessionHasPermissionBlockProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentSessionHasPermissionBlockHash() =>
    r'06f083e93aa655013d3a57f2cac0d64823e6f273';

final class CurrentSessionHasPermissionBlockFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  CurrentSessionHasPermissionBlockFamily._()
    : super(
        retry: null,
        name: r'currentSessionHasPermissionBlockProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CurrentSessionHasPermissionBlockProvider call(String sessionID) =>
      CurrentSessionHasPermissionBlockProvider._(
        argument: sessionID,
        from: this,
      );

  @override
  String toString() => r'currentSessionHasPermissionBlockProvider';
}
