// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatConfigNotifier)
final chatConfigProvider = ChatConfigNotifierProvider._();

final class ChatConfigNotifierProvider
    extends $AsyncNotifierProvider<ChatConfigNotifier, ChatConfig> {
  ChatConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatConfigNotifierHash();

  @$internal
  @override
  ChatConfigNotifier create() => ChatConfigNotifier();
}

String _$chatConfigNotifierHash() =>
    r'a970b4c59e4d33d419caf5843ab427412471654e';

abstract class _$ChatConfigNotifier extends $AsyncNotifier<ChatConfig> {
  FutureOr<ChatConfig> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ChatConfig>, ChatConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatConfig>, ChatConfig>,
              AsyncValue<ChatConfig>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
