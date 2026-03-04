import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/message.dart';
import '../service/api/provider_api.dart';
import 'session_provider.dart';

part 'chat_config_provider.g.dart';

const _kDefaultAgent = 'build';
const _kFallbackProviderID = 'opencode';
const _kFallbackModelID = 'minimax-m2.5-free';

class ChatConfig {
  final String agent;
  final MessageModel model;

  const ChatConfig({required this.agent, required this.model});

  ChatConfig copyWith({String? agent, MessageModel? model}) {
    return ChatConfig(agent: agent ?? this.agent, model: model ?? this.model);
  }

  @override
  String toString() =>
      'ChatConfig(agent: $agent, providerID: ${model.providerID},'
      ' modelID: ${model.modelID})';
}

@riverpod
class ChatConfigNotifier extends _$ChatConfigNotifier {
  @override
  Future<ChatConfig> build() async {
    // Step 1: find the last UserMessage in the current session.
    // Use .future to properly await the messages, avoiding a race condition
    // where the watch subscription is established after an intermediate await,
    // which causes Riverpod's pausedActiveSubscriptionCount assertion to fail.
    final messages = await ref.watch(sessionMessagesProvider.future);
    if (messages.isNotEmpty) {
      final lastUser = messages.lastWhere(
        (m) => m.info is UserMessage,
        orElse: () => throw StateError('no user message'),
      );
      if (lastUser.info case final UserMessage msg) {
        return ChatConfig(agent: msg.agent, model: msg.model);
      }
    }

    // Step 2: call /provider to find the first connected provider and its
    // default model.
    try {
      final api = ref.read(providerApiProvider);
      final response = await api.list();

      if (response.connected.isNotEmpty) {
        final providerID = response.connected.first;
        final modelID = response.defaultProvider[providerID];
        if (modelID != null) {
          return ChatConfig(
            agent: _kDefaultAgent,
            model: MessageModel(providerID: providerID, modelID: modelID),
          );
        }
      }
    } catch (_) {
      // Fall through to fallback.
    }

    // Step 3: hardcoded fallback.
    return ChatConfig(
      agent: _kDefaultAgent,
      model: MessageModel(
        providerID: _kFallbackProviderID,
        modelID: _kFallbackModelID,
      ),
    );
  }

  void setAgent(String agent) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(agent: agent));
  }

  void setModel(MessageModel model) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(model: model));
  }
}
