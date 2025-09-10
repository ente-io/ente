import 'package:flutter/material.dart';
import 'package:log_viewer/src/core/log_models.dart';

/// Dialog for configuring log filters
class LogFilterDialog extends StatefulWidget {
  final List<String> availableLoggers;
  final List<String> availableProcesses;
  final LogFilter currentFilter;

  const LogFilterDialog({
    super.key,
    required this.availableLoggers,
    required this.availableProcesses,
    required this.currentFilter,
  });

  @override
  State<LogFilterDialog> createState() => _LogFilterDialogState();
}

class _LogFilterDialogState extends State<LogFilterDialog> {
  late Set<String> _selectedLoggers;
  late Set<String> _selectedLevels;
  late Set<String> _selectedProcesses;
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _selectedLoggers = Set.from(widget.currentFilter.selectedLoggers);
    _selectedLevels = Set.from(widget.currentFilter.selectedLevels);
    _selectedProcesses = Set.from(widget.currentFilter.selectedProcesses);
    _startTime = widget.currentFilter.startTime;
    _endTime = widget.currentFilter.endTime;
  }

  void _applyFilters() {
    final newFilter = LogFilter(
      selectedLoggers: _selectedLoggers,
      selectedLevels: _selectedLevels,
      selectedProcesses: _selectedProcesses,
      searchQuery: widget.currentFilter.searchQuery,
      startTime: _startTime,
      endTime: _endTime,
    );
    Navigator.pop(context, newFilter);
  }

  void _clearFilters() {
    setState(() {
      _selectedLoggers.clear();
      _selectedLevels.clear();
      _selectedProcesses.clear();
    });
  }


  Widget _buildLevelChip(String level) {
    final isSelected = _selectedLevels.contains(level);
    final color = LogEntry(
      message: '',
      level: level,
      timestamp: DateTime.now(),
      loggerName: '',
    ).levelColor;

    return FilterChip(
      label: Text(
        level,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedLevels.add(level);
          } else {
            _selectedLevels.remove(level);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Logs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Log Levels
                    Text(
                      'Log Levels',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LogLevels.all
                          .where((level) => level != 'ALL' && level != 'OFF')
                          .map(_buildLevelChip)
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Loggers
                    if (widget.availableLoggers.isNotEmpty) ...[
                      Text(
                        'Loggers',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.availableLoggers.length,
                          itemBuilder: (context, index) {
                            final logger = widget.availableLoggers[index];
                            return CheckboxListTile(
                              title: Text(
                                logger,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: _selectedLoggers.contains(logger),
                              dense: true,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedLoggers.add(logger);
                                  } else {
                                    _selectedLoggers.remove(logger);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Processes
                    if (widget.availableProcesses.isNotEmpty) ...[
                      Text(
                        'Processes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.availableProcesses.length,
                          itemBuilder: (context, index) {
                            final process = widget.availableProcesses[index];
                            final displayName = LogEntry(
                              message: '',
                              level: 'INFO',
                              timestamp: DateTime.now(),
                              loggerName: '',
                              processPrefix: process,
                            ).processDisplayName;
                            return CheckboxListTile(
                              title: Text(
                                displayName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: process.isNotEmpty 
                                  ? Text(
                                      'Prefix: $process',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    )
                                  : null,
                              value: _selectedProcesses.contains(process),
                              dense: true,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedProcesses.add(process);
                                  } else {
                                    _selectedProcesses.remove(process);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
