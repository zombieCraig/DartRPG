import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../models/clock.dart';
import '../../models/faction.dart';
import 'faction_dialog.dart';
import 'faction_service.dart';

/// A card for displaying a faction
class FactionCard extends StatefulWidget {
  final Faction faction;
  final List<Clock> clocks;
  final List<Faction> allFactions;
  final FactionService factionService;

  const FactionCard({
    super.key,
    required this.faction,
    required this.clocks,
    required this.allFactions,
    required this.factionService,
  });

  @override
  State<FactionCard> createState() => _FactionCardState();
}

class _FactionCardState extends State<FactionCard> {
  bool _isExpanded = false;

  List<Clock> get _associatedClocks {
    return widget.faction.clockIds
        .map((id) => widget.clocks.firstWhereOrNull((c) => c.id == id))
        .whereType<Clock>()
        .toList();
  }

  String? _resolveFactionName(String factionId) {
    final faction = widget.allFactions.firstWhereOrNull((f) => f.id == factionId);
    return faction?.name;
  }

  @override
  Widget build(BuildContext context) {
    final associatedClocks = _associatedClocks;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.faction.type.color.withAlpha(128),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(widget.faction.type.icon, color: widget.faction.type.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.faction.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.faction.type.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.faction.influence.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.faction.type.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),

              // Type label + subtypes
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      widget.faction.type.displayName,
                      style: TextStyle(
                        color: widget.faction.type.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (associatedClocks.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        '${associatedClocks.length} clock${associatedClocks.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Subtypes chips (always visible if present)
              if (widget.faction.subtypes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.faction.subtypes.map((subtype) {
                      return Chip(
                        label: Text(subtype, style: const TextStyle(fontSize: 11)),
                        backgroundColor: widget.faction.type.color.withAlpha(20),
                        side: BorderSide(color: widget.faction.type.color.withAlpha(60)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      );
                    }).toList(),
                  ),
                ),

              // Expanded content
              if (_isExpanded) ...[
                if (widget.faction.leadershipStyle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildLabeledField(
                    Icons.people_outline, 'Leadership', widget.faction.leadershipStyle,
                  ),
                ],

                if (widget.faction.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.faction.description,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],

                if (widget.faction.projects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection(Icons.assignment_outlined, 'Projects', widget.faction.projects),
                ],

                if (widget.faction.quirks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection(Icons.star_outline, 'Quirks', widget.faction.quirks),
                ],

                if (widget.faction.rumors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection(Icons.chat_bubble_outline, 'Rumors', widget.faction.rumors),
                ],

                // Relationships
                if (widget.faction.relationships.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.handshake_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'Relationships',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...widget.faction.relationships.entries.map((entry) {
                    final otherName = _resolveFactionName(entry.key) ?? 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 2),
                      child: Text(
                        '\u2022 ${entry.value} $otherName',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    );
                  }),
                ],

                // Associated clocks
                if (associatedClocks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Clocks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...associatedClocks.map((clock) => _buildClockRow(clock)),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('Add Clock'),
                      onPressed: () => _addClock(context),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () => _editFaction(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () => _deleteFaction(context),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],

              // Collapsed hint
              if (!_isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap to expand',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            content,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildClockRow(Clock clock) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(clock.type.icon, color: clock.type.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clock.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${clock.progress}/${clock.segments} - ${clock.type.displayName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: clock.isComplete
                ? null
                : () async {
                    clock.advance();
                    await widget.factionService.gameProvider.persistAndNotify();
                  },
            tooltip: 'Advance',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.link_off, size: 20),
            onPressed: () => _removeClockFromFaction(clock),
            tooltip: 'Unlink clock',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _addClock(BuildContext context) async {
    final result = await FactionDialog.showAddClockDialog(context: context);
    if (result != null && context.mounted) {
      await widget.factionService.addClockToFaction(
        factionId: widget.faction.id,
        title: result['title'],
        segments: result['segments'],
        type: result['type'],
      );
    }
  }

  void _editFaction(BuildContext context) async {
    final result = await FactionDialog.showEditDialog(
      context: context,
      faction: widget.faction,
    );
    if (result != null && context.mounted) {
      await widget.factionService.updateFaction(
        factionId: widget.faction.id,
        name: result['name'],
        type: result['type'],
        influence: result['influence'],
        description: result['description'],
        leadershipStyle: result['leadershipStyle'],
        subtypes: result['subtypes'],
        projects: result['projects'],
        quirks: result['quirks'],
        rumors: result['rumors'],
      );
    }
  }

  void _deleteFaction(BuildContext context) async {
    final confirmed = await FactionDialog.showDeleteConfirmation(
      context: context,
      faction: widget.faction,
    );
    if (confirmed == true && context.mounted) {
      await widget.factionService.deleteFaction(widget.faction.id);
    }
  }

  void _removeClockFromFaction(Clock clock) async {
    await widget.factionService.removeClockFromFaction(
      factionId: widget.faction.id,
      clockId: clock.id,
    );
  }
}
