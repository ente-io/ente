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
          color: isSelected ? Colors.white : color,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.15),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Logs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Log Levels
                    Text(
                      'Log Levels',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LogLevels.all
                          .where((level) => level != 'ALL' && level != 'OFF')
                          .map(_buildLevelChip)
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // Loggers
                    if (widget.availableLoggers.isNotEmpty) ...[
                      Text(
                        'Loggers',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: theme.cardColor,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: widget.availableLoggers.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: theme.dividerColor.withValues(alpha: 0.3),
                            ),
                            itemBuilder: (context, index) {
                              final logger = widget.availableLoggers[index];
                              final isSelected =
                                  _selectedLoggers.contains(logger);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedLoggers.remove(logger);
                                    } else {
                                      _selectedLoggers.add(logger);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          logger,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? theme.primaryColor
                                                : theme
                                                    .textTheme.bodyLarge?.color,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: (selected) {
                                            setState(() {
                                              if (selected == true) {
                                                _selectedLoggers.add(logger);
                                              } else {
                                                _selectedLoggers.remove(logger);
                                              }
                                            });
                                          },
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _applyFilters,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
