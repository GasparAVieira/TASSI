import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NewDiaryEntryCard extends StatefulWidget {
  final VoidCallback onCancel;
  final bool isPrivate;
  final bool isAttachmentProcessing;
  final bool isSaving;
  final ValueChanged<bool> onPrivacyChanged;
  final Function(String title, String notes) onSave;

  const NewDiaryEntryCard({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.isPrivate,
    required this.isAttachmentProcessing,
    required this.onPrivacyChanged,
    this.isSaving = false,
  });

  @override
  State<NewDiaryEntryCard> createState() => _NewDiaryEntryCardState();
}

class _NewDiaryEntryCardState extends State<NewDiaryEntryCard> {
  static const int _titleMaxLength = 60;
  static const int _notesMaxLength = 1200;

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String? _titleError;
  String? _notesError;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    final titleText = _titleController.text.trim();
    final notesText = _notesController.text.trim();

    setState(() {
      _titleError = titleText.isEmpty
          ? 'Title is required'
          : titleText.length > _titleMaxLength
              ? 'Title cannot exceed $_titleMaxLength characters'
              : null;
      _notesError = notesText.isNotEmpty && notesText.length > _notesMaxLength
          ? 'Notes cannot exceed $_notesMaxLength characters'
          : null;
    });

    if (_titleError == null && _notesError == null) {
      widget.onSave(titleText, notesText);
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildErrorText(ThemeData theme, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.error, color: theme.colorScheme.error, size: 14),
          const SizedBox(width: 4),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryChip(
    ThemeData theme,
    String label, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor ?? theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildTextFieldWithCounter({
    required ThemeData theme,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required int maxLength,
    required int maxLines,
    required ValueChanged<String> onChanged,
    bool showError = false,
    String? errorText,
  }) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
            counterText: '',
            errorText: showError ? errorText : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 12, 8),
          child: Text(
            '${controller.text.length}/$maxLength',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Matches Diary Entry Card)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleController.text.trim().isEmpty
                          ? 'Create New Entry'
                          : _titleController.text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildEntryChip(theme, _getFormattedDate()),
                  const SizedBox(width: 8),
                  _buildEntryChip(
                    theme,
                    widget.isPrivate ? 'Private' : 'Public',
                    backgroundColor: widget.isPrivate
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.tertiaryContainer,
                    textColor: widget.isPrivate
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Divider (Matches Diary Entry Card)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextFieldWithCounter(
                theme: theme,
                controller: _titleController,
                labelText: 'Entry Title',
                hintText: 'e.g. Day One on Campus',
                maxLength: _titleMaxLength,
                maxLines: 1,
                onChanged: (v) => setState(() => _titleError = null),
              ),
              if (_titleError != null) ...[
                _buildErrorText(theme, _titleError!),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 16),
              _buildTextFieldWithCounter(
                theme: theme,
                controller: _notesController,
                labelText: 'Notes',
                hintText: 'Describe your experience...',
                maxLength: _notesMaxLength,
                maxLines: 4,
                onChanged: (v) => setState(() => _notesError = null),
              ),
              if (_notesError != null) ...[
                _buildErrorText(theme, _notesError!),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Entry',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isPrivate
                              ? 'This entry is private. Turn on to share it publicly.'
                              : 'This entry is public. Turn off to keep it private.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: !widget.isPrivate,
                    onChanged: (value) => widget.onPrivacyChanged(!value),
                  ),
                ],
              ),


            ],
          ),
        ),

        // Save Button (Matches Diary Entry Card style)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (widget.isAttachmentProcessing || widget.isSaving) ? null : _validateAndSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: widget.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Entry'),
            ),
          ),
        ),
      ],
    );
  }
}
