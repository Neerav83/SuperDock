import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import 'glass_card.dart';

class GitAddDialog extends StatefulWidget {
  const GitAddDialog({
    super.key,
    required this.files,
  });

  final List<GitChangeFile> files;

  @override
  State<GitAddDialog> createState() => _GitAddDialogState();
}

class _GitAddDialogState extends State<GitAddDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.files.map((file) => file.path).toSet();
  }

  ({String fileName, String directory}) _splitPath(String path) {
    final normalized = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash == -1) {
      return (fileName: normalized, directory: '');
    }
    return (
      fileName: normalized.substring(lastSlash + 1),
      directory: normalized.substring(0, lastSlash),
    );
  }

  Widget _buildFileRow({
    required GitChangeFile file,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    final parts = _splitPath(file.path);

    return Tooltip(
      message: file.path,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parts.fileName.isNotEmpty ? parts.fileName : file.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (parts.directory.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        parts.directory,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      file.statusLabel,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      _selected
        ..clear()
        ..addAll(selectAll ? widget.files.map((file) => file.path) : const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == widget.files.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Välj filer att stagea',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Markera filerna som ska läggas till med git add.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: widget.files.isEmpty
                      ? null
                      : () => _toggleAll(!allSelected),
                  child: Text(allSelected ? 'Avmarkera alla' : 'Markera alla'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: widget.files.isEmpty
                      ? Center(
                          child: Text(
                            'Inga ändrade filer att stagea.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: widget.files.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final file = widget.files[index];
                            final isSelected = _selected.contains(file.path);

                            return _buildFileRow(
                              file: file,
                              isSelected: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selected.add(file.path);
                                  } else {
                                    _selected.remove(file.path);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Avbryt'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_selected.toList()),
                      child: const Text('Stagea valda'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
