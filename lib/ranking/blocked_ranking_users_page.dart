import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'ranking_safety_store.dart';

class BlockedRankingUsersPage extends StatefulWidget {
  const BlockedRankingUsersPage({super.key, required this.safetyStore});

  final RankingSafetyStore safetyStore;

  @override
  State<BlockedRankingUsersPage> createState() =>
      _BlockedRankingUsersPageState();
}

class _BlockedRankingUsersPageState extends State<BlockedRankingUsersPage> {
  late Future<List<BlockedRankingActor>> _actors =
      widget.safetyStore.blockedActors();

  Future<void> _unblock(BlockedRankingActor actor) async {
    await widget.safetyStore.unhideActor(actor.actorId);
    if (!mounted) return;
    setState(() {
      _actors = widget.safetyStore.blockedActors();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const ValueKey('blocked-ranking-users-page'),
        backgroundColor: const Color(0xFFE8F8FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE8F8FF),
          title: Text(context.l10n.blockedRankingUsers),
        ),
        body: SafeArea(
          child: FutureBuilder<List<BlockedRankingActor>>(
            future: _actors,
            builder: (context, snapshot) {
              final actors = snapshot.data;
              if (actors == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (actors.isEmpty) {
                return Center(
                  key: const ValueKey('blocked-ranking-users-empty'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.blockedRankingUsersEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: actors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final actor = actors[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        actor.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        key: ValueKey('unblock-ranking-user-${actor.actorId}'),
                        onPressed: () => _unblock(actor),
                        child: Text(context.l10n.unblockRankingUser),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
