import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/permission_provider.dart';
import '../../service/api/models/permission.dart';

class SessionPermissionDock extends ConsumerWidget {
  const SessionPermissionDock({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingPermissionsProvider);
    final notifier = ref.read(pendingPermissionsProvider.notifier);
    final responding = notifier.isResponding(request.id);

    Future<void> decide(PermissionReplyAction action) async {
      try {
        await notifier.respond(request, reply: action);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Permission reply failed: $e')));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Permission Request',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${request.permission} · ${request.patterns.join(', ')}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.reject),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[200]!),
                  ),
                  child: const Text('Deny'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.always),
                  child: const Text('Allow always'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.once),
                  child: const Text('Allow once'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
