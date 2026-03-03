// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessageCache)
final messageCacheProvider = MessageCacheProvider._();

final class MessageCacheProvider
    extends
        $NotifierProvider<MessageCache, Map<String, List<MessageWithParts>>> {
  MessageCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageCacheHash();

  @$internal
  @override
  MessageCache create() => MessageCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<MessageWithParts>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<MessageWithParts>>>(
        value,
      ),
    );
  }
}

String _$messageCacheHash() => r'ea206d0aac4f6a8365bc9bdb0162c22091b2ff0f';

abstract class _$MessageCache
    extends $Notifier<Map<String, List<MessageWithParts>>> {
  Map<String, List<MessageWithParts>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, List<MessageWithParts>>,
              Map<String, List<MessageWithParts>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<MessageWithParts>>,
                Map<String, List<MessageWithParts>>
              >,
              Map<String, List<MessageWithParts>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
