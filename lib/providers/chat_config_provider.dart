import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/agent.dart' as agent_model;
import '../service/api/models/message.dart';
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

@Riverpod(keepAlive: true)
class ChatConfigNotifier extends _$ChatConfigNotifier {
  @override
  ChatConfig build() {
    // Listen for session changes and sync the model when switching to an
    // existing session. Uses listen (not watch) so that message updates never
    // trigger a full rebuild of this notifier.
    ref.listen(selectedSessionProvider, (previous, next) async {
      final newSession = next.session;

      // New-session flow (isPending=true) or nothing selected: preserve the
      // current model so the user's last choice is not overwritten.
      if (next.isPending || newSession == null) return;

      // Same session selected again – nothing to do.
      if (newSession.id == previous?.session?.id) return;

      // Switched to an existing session: try to restore its last-used model.
      await _syncModelFromSession();
    });

    return ChatConfig(
      agent: _kDefaultAgent,
      model: MessageModel(
        providerID: _kFallbackProviderID,
        modelID: _kFallbackModelID,
      ),
    );
  }

  /// Reads the messages of the currently selected session once (no watch) and
  /// updates the model to match the last UserMessage. If the session has no
  /// messages the current model is preserved.
  Future<void> _syncModelFromSession() async {
    final messages = await ref.read(sessionMessagesProvider.future);
    if (messages.isEmpty) return;

    try {
      final lastUser = messages.lastWhere((m) => m.info is UserMessage);
      if (lastUser.info case final UserMessage msg) {
        state = state.copyWith(agent: msg.agent, model: msg.model);
      }
    } on StateError {
      // No UserMessage found – preserve current model.
    }
  }

  /// Sets the active agent. If [linkedModel] is provided (from the agent's
  /// bound model field), the model is also updated automatically.
  void setAgent(String agent, {agent_model.AgentModel? linkedModel}) {
    var newState = state.copyWith(agent: agent);
    if (linkedModel != null) {
      newState = newState.copyWith(
        model: MessageModel(
          providerID: linkedModel.providerID,
          modelID: linkedModel.modelID,
        ),
      );
    }
    state = newState;
  }

  void setModel(MessageModel model) {
    state = state.copyWith(model: model);
  }
}
