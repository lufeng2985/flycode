// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSessionNotifier)
final selectedSessionProvider = SelectedSessionNotifierProvider._();

final class SelectedSessionNotifierProvider
    extends $NotifierProvider<SelectedSessionNotifier, Session?> {
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
  Override overrideWithValue(Session? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session?>(value),
    );
  }
}

String _$selectedSessionNotifierHash() =>
    r'611ba35f01dc9fbb7d62f320f4dca1bc4c6c7043';

abstract class _$SelectedSessionNotifier extends $Notifier<Session?> {
  Session? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Session?, Session?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Session?, Session?>,
              Session?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
