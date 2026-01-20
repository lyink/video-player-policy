import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';

class SmartPlaylistCreator extends StatefulWidget {
  final PlaylistProvider playlistProvider;
  final Playlist? editingPlaylist;

  const SmartPlaylistCreator({
    super.key,
    required this.playlistProvider,
    this.editingPlaylist,
  });

  @override
  State<SmartPlaylistCreator> createState() => _SmartPlaylistCreatorState();
}

class _SmartPlaylistCreatorState extends State<SmartPlaylistCreator> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxItemsController;

  List<SmartPlaylistRule> _rules = [];
  PlaylistSortBy _sortBy = PlaylistSortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  bool _isAutoUpdate = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _maxItemsController = TextEditingController(text: '1000');

    if (widget.editingPlaylist != null) {
      _loadExistingPlaylist();
    }
  }

  void _loadExistingPlaylist() {
    final playlist = widget.editingPlaylist!;
    _nameController.text = playlist.name;
    _descriptionController.text = playlist.description;
    _maxItemsController.text = playlist.maxItems.toString();
    _rules = List.from(playlist.smartRules);
    _sortBy = playlist.sortBy;
    _sortOrder = playlist.sortOrder;
    _isAutoUpdate = playlist.isAutoUpdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxItemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingPlaylist != null
              ? 'Edit Smart Playlist'
              : 'Create Smart Playlist',
        ),
        actions: [
          TextButton(onPressed: _savePlaylist, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildRulesSection(),
            const SizedBox(height: 24),
            _buildSortingSection(),
            const SizedBox(height: 24),
            _buildOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter playlist name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Smart Rules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addRule,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rule'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rules.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rule,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No rules added yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add rules to automatically populate this playlist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._rules.asMap().entries.map((entry) {
                final index = entry.key;
                final rule = entry.value;
                return _buildRuleItem(rule, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(SmartPlaylistRule rule, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rule.criteria.name} ${rule.operator} "${rule.value}"',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (rule.caseSensitive)
                  Text(
                    'Case sensitive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editRule(index),
            tooltip: 'Edit rule',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _removeRule(index),
            tooltip: 'Remove rule',
          ),
        ],
      ),
    );
  }

  Widget _buildSortingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorting',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PlaylistSortBy>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                    ),
                    items: PlaylistSortBy.values.map((sortBy) {
                      return DropdownMenuItem(
                        value: sortBy,
                        child: Text(_getSortByDisplayName(sortBy)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<SortOrder>(
                    value: _sortOrder,
                    decoration: const InputDecoration(
                      labelText: 'Order',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SortOrder.ascending,
                        child: Text('Ascending'),
                      ),
                      DropdownMenuItem(
                        value: SortOrder.descending,
                        child: Text('Descending'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortOrder = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxItemsController,
              decoration: const InputDecoration(
                labelText: 'Maximum Items',
                hintText: 'Enter maximum number of items',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Update'),
              subtitle: const Text('Automatically update when media changes'),
              value: _isAutoUpdate,
              onChanged: (value) {
                setState(() {
                  _isAutoUpdate = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addRule() {
    showDialog(
      context: context,
      builder: (context) => _RuleCreatorDialog(
        onRuleCreated: (rule) {
          setState(() {
            _rules.add(rule);
          });
        },
      ),
    );
  }

  void _editRule(int index) {
    showDialog(
      context: context,
      builder: (context) => _RuleCreatorDialog(
        existingRule: _rules[index],
        onRuleCreated: (rule) {
          setState(() {
            _rules[index] = rule;
          });
        },
      ),
    );
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  String _getSortByDisplayName(PlaylistSortBy sortBy) {
    switch (sortBy) {
      case PlaylistSortBy.name:
        return 'Name';
      case PlaylistSortBy.dateAdded:
        return 'Date Added';
      case PlaylistSortBy.duration:
        return 'Duration';
      case PlaylistSortBy.fileSize:
        return 'File Size';
      case PlaylistSortBy.lastModified:
        return 'Last Modified';
      case PlaylistSortBy.artist:
        return 'Artist';
      case PlaylistSortBy.album:
        return 'Album';
      case PlaylistSortBy.year:
        return 'Year';
      case PlaylistSortBy.playCount:
        return 'Play Count';
      case PlaylistSortBy.rating:
        return 'Rating';
      case PlaylistSortBy.custom:
        return 'Custom Order';
    }
  }

  void _savePlaylist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name')),
      );
      return;
    }

    if (_rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one rule')),
      );
      return;
    }

    final maxItems = int.tryParse(_maxItemsController.text) ?? 1000;

    try {
      if (widget.editingPlaylist != null) {
        // Update existing playlist
        final updatedPlaylist = widget.editingPlaylist!.copyWith(
          name: name,
          description: _descriptionController.text.trim(),
          smartRules: _rules,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          maxItems: maxItems,
          isAutoUpdate: _isAutoUpdate,
        );
        await widget.playlistProvider.updatePlaylist(
          widget.editingPlaylist!.id,
          updatedPlaylist,
        );
      } else {
        // Create new playlist
        await widget.playlistProvider.createSmartPlaylist(
          name: name,
          description: _descriptionController.text.trim(),
          rules: _rules,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          maxItems: maxItems,
          isAutoUpdate: _isAutoUpdate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingPlaylist != null
                  ? 'Updated "$name" playlist'
                  : 'Created "$name" smart playlist',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _RuleCreatorDialog extends StatefulWidget {
  final SmartPlaylistRule? existingRule;
  final Function(SmartPlaylistRule) onRuleCreated;

  const _RuleCreatorDialog({this.existingRule, required this.onRuleCreated});

  @override
  State<_RuleCreatorDialog> createState() => _RuleCreatorDialogState();
}

class _RuleCreatorDialogState extends State<_RuleCreatorDialog> {
  late SmartPlaylistCriteria _criteria;
  late String _operator;
  late TextEditingController _valueController;
  late bool _caseSensitive;

  final Map<SmartPlaylistCriteria, List<String>> _operatorOptions = {
    SmartPlaylistCriteria.genre: [
      'equals',
      'contains',
      'starts_with',
      'ends_with',
    ],
    SmartPlaylistCriteria.artist: [
      'equals',
      'contains',
      'starts_with',
      'ends_with',
    ],
    SmartPlaylistCriteria.album: [
      'equals',
      'contains',
      'starts_with',
      'ends_with',
    ],
    SmartPlaylistCriteria.year: [
      'equals',
      'greater_than',
      'less_than',
      'greater_equal',
      'less_equal',
    ],
    SmartPlaylistCriteria.duration: [
      'greater_than',
      'less_than',
      'greater_equal',
      'less_equal',
    ],
    SmartPlaylistCriteria.fileSize: [
      'greater_than',
      'less_than',
      'greater_equal',
      'less_equal',
    ],
    SmartPlaylistCriteria.dateAdded: ['greater_than', 'less_than'],
    SmartPlaylistCriteria.lastPlayed: ['greater_than', 'less_than'],
    SmartPlaylistCriteria.playCount: ['equals', 'greater_than', 'less_than'],
    SmartPlaylistCriteria.fileType: ['equals'],
    SmartPlaylistCriteria.folderPath: [
      'equals',
      'contains',
      'starts_with',
      'ends_with',
    ],
  };

  @override
  void initState() {
    super.initState();

    if (widget.existingRule != null) {
      _criteria = widget.existingRule!.criteria;
      _operator = widget.existingRule!.operator;
      _valueController = TextEditingController(
        text: widget.existingRule!.value,
      );
      _caseSensitive = widget.existingRule!.caseSensitive;
    } else {
      _criteria = SmartPlaylistCriteria.genre;
      _operator = 'equals';
      _valueController = TextEditingController();
      _caseSensitive = false;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingRule != null ? 'Edit Rule' : 'Add Rule'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<SmartPlaylistCriteria>(
              value: _criteria,
              decoration: const InputDecoration(
                labelText: 'Criteria',
                border: OutlineInputBorder(),
              ),
              items: SmartPlaylistCriteria.values.map((criteria) {
                return DropdownMenuItem(
                  value: criteria,
                  child: Text(_getCriteriaDisplayName(criteria)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _criteria = value!;
                  _operator = _operatorOptions[_criteria]!.first;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _operator,
              decoration: const InputDecoration(
                labelText: 'Operator',
                border: OutlineInputBorder(),
              ),
              items: _operatorOptions[_criteria]!.map((operator) {
                return DropdownMenuItem(
                  value: operator,
                  child: Text(_getOperatorDisplayName(operator)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _operator = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: _getValueHint(_criteria, _operator),
                border: const OutlineInputBorder(),
              ),
              keyboardType: _isNumericCriteria(_criteria)
                  ? TextInputType.number
                  : TextInputType.text,
            ),
            const SizedBox(height: 16),
            if (_isTextCriteria(_criteria))
              SwitchListTile(
                title: const Text('Case Sensitive'),
                value: _caseSensitive,
                onChanged: (value) {
                  setState(() {
                    _caseSensitive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveRule, child: const Text('Save')),
      ],
    );
  }

  String _getCriteriaDisplayName(SmartPlaylistCriteria criteria) {
    switch (criteria) {
      case SmartPlaylistCriteria.genre:
        return 'Genre';
      case SmartPlaylistCriteria.artist:
        return 'Artist';
      case SmartPlaylistCriteria.album:
        return 'Album';
      case SmartPlaylistCriteria.year:
        return 'Year';
      case SmartPlaylistCriteria.duration:
        return 'Duration';
      case SmartPlaylistCriteria.fileSize:
        return 'File Size';
      case SmartPlaylistCriteria.dateAdded:
        return 'Date Added';
      case SmartPlaylistCriteria.lastPlayed:
        return 'Last Played';
      case SmartPlaylistCriteria.playCount:
        return 'Play Count';
      case SmartPlaylistCriteria.fileType:
        return 'File Type';
      case SmartPlaylistCriteria.folderPath:
        return 'Folder Path';
    }
  }

  String _getOperatorDisplayName(String operator) {
    switch (operator) {
      case 'equals':
        return 'Equals';
      case 'contains':
        return 'Contains';
      case 'starts_with':
        return 'Starts With';
      case 'ends_with':
        return 'Ends With';
      case 'greater_than':
        return 'Greater Than';
      case 'less_than':
        return 'Less Than';
      case 'greater_equal':
        return 'Greater or Equal';
      case 'less_equal':
        return 'Less or Equal';
      default:
        return operator;
    }
  }

  String _getValueHint(SmartPlaylistCriteria criteria, String operator) {
    switch (criteria) {
      case SmartPlaylistCriteria.duration:
        return 'Duration in seconds (e.g., 180 for 3 minutes)';
      case SmartPlaylistCriteria.fileSize:
        return 'Size in bytes (e.g., 104857600 for 100MB)';
      case SmartPlaylistCriteria.dateAdded:
      case SmartPlaylistCriteria.lastPlayed:
        return 'Days ago (e.g., 7 for last week)';
      case SmartPlaylistCriteria.fileType:
        return 'video or audio';
      default:
        return 'Enter value';
    }
  }

  bool _isNumericCriteria(SmartPlaylistCriteria criteria) {
    return [
      SmartPlaylistCriteria.year,
      SmartPlaylistCriteria.duration,
      SmartPlaylistCriteria.fileSize,
      SmartPlaylistCriteria.dateAdded,
      SmartPlaylistCriteria.lastPlayed,
      SmartPlaylistCriteria.playCount,
    ].contains(criteria);
  }

  bool _isTextCriteria(SmartPlaylistCriteria criteria) {
    return [
      SmartPlaylistCriteria.genre,
      SmartPlaylistCriteria.artist,
      SmartPlaylistCriteria.album,
      SmartPlaylistCriteria.folderPath,
    ].contains(criteria);
  }

  void _saveRule() {
    final value = _valueController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a value')));
      return;
    }

    final rule = SmartPlaylistRule(
      criteria: _criteria,
      operator: _operator,
      value: value,
      caseSensitive: _caseSensitive,
    );

    widget.onRuleCreated(rule);
    Navigator.pop(context);
  }
}
