import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/network_route.dart';
import 'route_card.dart';
import 'route_dialog.dart';
import 'route_service.dart';

/// A list of network routes
class RouteTabList extends StatelessWidget {
  final List<NetworkRoute> routes;
  final List<Character> characters;
  final RouteService routeService;

  const RouteTabList({
    super.key,
    required this.routes,
    required this.characters,
    required this.routeService,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No routes yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Map a new route using the + button',
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
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final character = characters.firstWhere(
          (c) => c.id == route.characterId,
          orElse: () => throw Exception('Character not found'),
        );

        return RouteCard(
          route: route,
          character: character,
          onProgressChanged: (value) {
            routeService.updateProgress(route.id, value);
          },
          onProgressRoll: () async {
            final result =
                await routeService.makeProgressRoll(route.id);
            if (result != null && context.mounted) {
              RouteDialog.showProgressRollResult(
                context: context,
                route: route,
                result: result,
              );
            }
          },
          onAdvance: () {
            routeService.addTicksForRank(route.id);
          },
          onDecrease: () {
            routeService.removeTicksForRank(route.id);
          },
          onComplete: () {
            routeService.completeRoute(route.id);
          },
          onBurn: () {
            routeService.burnRoute(route.id);
          },
          onDelete: () async {
            final shouldDelete = await RouteDialog.showDeleteConfirmation(
              context: context,
              route: route,
            );
            if (shouldDelete == true && context.mounted) {
              routeService.deleteRoute(route.id);
            }
          },
          onEdit: () async {
            final result = await RouteDialog.showEditDialog(
              context: context,
              route: route,
              characters: characters,
            );
            if (result != null && context.mounted) {
              routeService.updateRoute(
                routeId: route.id,
                name: result['name'],
                origin: result['origin'],
                destination: result['destination'],
                rank: result['rank'],
                notes: result['notes'],
              );
            }
          },
          onNotesChanged: (notes) {
            routeService.updateNotes(route.id, notes);
          },
        );
      },
    );
  }
}
