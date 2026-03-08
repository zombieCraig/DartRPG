import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/connection.dart';
import 'connection_card.dart';
import 'connection_dialog.dart';
import 'connection_service.dart';

/// A list of connections, optionally filtered by status
class ConnectionTabList extends StatelessWidget {
  final List<Connection> connections;
  final List<Character> characters;
  final ConnectionService connectionService;

  const ConnectionTabList({
    super.key,
    required this.connections,
    required this.characters,
    required this.connectionService,
  });

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No connections yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new connection using the + button',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        final character = characters.firstWhere(
          (c) => c.id == connection.characterId,
          orElse: () => throw Exception('Character not found'),
        );

        return ConnectionCard(
          connection: connection,
          character: character,
          onProgressChanged: (value) {
            connectionService.updateProgress(connection.id, value);
          },
          onProgressRoll: () async {
            final result =
                await connectionService.makeProgressRoll(connection.id);
            if (result != null && context.mounted) {
              ConnectionDialog.showProgressRollResult(
                context: context,
                connection: connection,
                result: result,
              );
            }
          },
          onAdvance: () {
            connectionService.addTicksForRank(connection.id);
          },
          onDecrease: () {
            connectionService.removeTicksForRank(connection.id);
          },
          onBond: () {
            connectionService.bondConnection(connection.id);
          },
          onLose: () {
            connectionService.loseConnection(connection.id);
          },
          onDelete: () async {
            final shouldDelete = await ConnectionDialog.showDeleteConfirmation(
              context: context,
              connection: connection,
            );
            if (shouldDelete == true && context.mounted) {
              connectionService.deleteConnection(connection.id);
            }
          },
          onEdit: () async {
            final result = await ConnectionDialog.showEditDialog(
              context: context,
              connection: connection,
              characters: characters,
            );
            if (result != null && context.mounted) {
              connectionService.updateConnection(
                connectionId: connection.id,
                name: result['name'],
                role: result['role'],
                rank: result['rank'],
                notes: result['notes'],
              );
            }
          },
          onNotesChanged: (notes) {
            connectionService.updateNotes(connection.id, notes);
          },
        );
      },
    );
  }
}
