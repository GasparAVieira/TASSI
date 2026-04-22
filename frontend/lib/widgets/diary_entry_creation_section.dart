import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/diary_entry.dart';
import '../services/settings_service.dart';
import 'new_diary_entry_card.dart';

typedef DiaryEntrySaveCallback =
    Future<void> Function(
      String title,
      String notes,
      bool isPrivate,
      List<Attachment> attachments,
    );

class DiaryEntryCreationSection extends StatefulWidget {
  final TabController tabController;
  final SettingsService settings;
  final DiaryEntrySaveCallback onSave;
  final VoidCallback onCancel;

  const DiaryEntryCreationSection({
    super.key,
    required this.tabController,
    required this.settings,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<DiaryEntryCreationSection> createState() =>
      _DiaryEntryCreationSectionState();
}

class _DiaryEntryCreationSectionState extends State<DiaryEntryCreationSection> {
  final PageController _attachmentPageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isPrivate = true;
  bool _isAttachmentProcessing = false;
  bool _isRequestingPermission = false;
  int _attachmentPageIndex = 0;
  int? _pendingDeleteAttachmentIndex;
  final List<Attachment> _newEntryMedia = [];

  @override
  void dispose() {
    _attachmentPageController.dispose();
    super.dispose();
  }

  void _showMediaChoice(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: double.infinity,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                type == 'Audio'
                    ? Icons.mic
                    : type == 'Image'
                    ? Icons.camera_alt
                    : Icons.videocam,
              ),
              title: Text('Record/Take New $type'),
              onTap: () {
                Navigator.pop(context);
                if (type == 'Image') {
                  _captureImage();
                } else if (type == 'Video') {
                  _captureVideo();
                } else {
                  _showPermissionSnackbar(
                    'Audio capture is not available yet.',
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text('Pick Existing $type'),
              onTap: () {
                Navigator.pop(context);
                if (type == 'Image') {
                  _selectImage();
                } else if (type == 'Video') {
                  _selectVideo();
                } else {
                  _showPermissionSnackbar(
                    'Audio file selection will be supported later.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    if (!await _requestCameraPermission()) return;
    setState(() {
      _isAttachmentProcessing = true;
    });
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (file == null) {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
      return;
    }

    final attachment = Attachment(
      name: file.name,
      type: 'Image',
      createdAt: DateTime.now(),
      sizeBytes: 0,
      path: file.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    if (_tryAddAttachment(attachment)) {
      final sizeBytes = await file.length();
      if (!mounted) return;
      setState(() {
        attachment.sizeBytes = sizeBytes;
      });
      _simulateAttachmentUpload(attachment);
    } else {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
    }
  }

  Future<void> _selectImage() async {
    if (!await _requestGalleryPermission(type: 'Image')) return;
    setState(() {
      _isAttachmentProcessing = true;
    });
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
      return;
    }

    final attachment = Attachment(
      name: file.name,
      type: 'Image',
      createdAt: DateTime.now(),
      sizeBytes: 0,
      path: file.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    if (_tryAddAttachment(attachment)) {
      final sizeBytes = await file.length();
      if (!mounted) return;
      setState(() {
        attachment.sizeBytes = sizeBytes;
      });
      _simulateAttachmentUpload(attachment);
    } else {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
    }
  }

  Future<void> _captureVideo() async {
    if (!await _requestCameraPermission()) return;
    if (!await _requestMicrophonePermission()) return;
    setState(() {
      _isAttachmentProcessing = true;
    });
    final file = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (file == null) {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
      return;
    }

    final attachment = Attachment(
      name: file.name,
      type: 'Video',
      createdAt: DateTime.now(),
      sizeBytes: 0,
      path: file.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    if (_tryAddAttachment(attachment)) {
      final sizeBytes = await file.length();
      if (!mounted) return;
      setState(() {
        attachment.sizeBytes = sizeBytes;
      });
      _simulateAttachmentUpload(attachment);
    } else {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
    }
  }

  Future<void> _selectVideo() async {
    if (!await _requestGalleryPermission(type: 'Video')) return;
    setState(() {
      _isAttachmentProcessing = true;
    });
    final file = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (file == null) {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
      return;
    }

    final attachment = Attachment(
      name: file.name,
      type: 'Video',
      createdAt: DateTime.now(),
      sizeBytes: 0,
      path: file.path,
      isUploading: true,
      uploadProgress: 0.0,
    );

    if (_tryAddAttachment(attachment)) {
      final sizeBytes = await file.length();
      if (!mounted) return;
      setState(() {
        attachment.sizeBytes = sizeBytes;
      });
      _simulateAttachmentUpload(attachment);
    } else {
      if (!mounted) return;
      setState(() {
        _isAttachmentProcessing = _newEntryMedia.any(
          (item) => item.isUploading,
        );
      });
    }
  }

  Future<bool> _requestPermission(Permission permission, String name) async {
    if (_isRequestingPermission) {
      return false;
    }

    _isRequestingPermission = true;
    try {
      final currentStatus = await permission.status;
      if (currentStatus.isGranted) return true;

      final status = await permission.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _showPermissionSnackbar(
          'Permission denied. Open settings to enable $name.',
          actionLabel: 'Settings',
          onActionPressed: openAppSettings,
        );
        return false;
      }

      _showPermissionSnackbar('Allow $name permission to continue.');
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    return _requestPermission(Permission.camera, 'camera');
  }

  Future<bool> _requestMicrophonePermission() async {
    return _requestPermission(Permission.microphone, 'microphone');
  }

  Future<bool> _requestGalleryPermission({required String type}) async {
    if (Platform.isIOS) {
      return _requestPermission(Permission.photos, 'photo library');
    }

    if (Platform.isAndroid) {
      if (type == 'Image') {
        return _requestPermission(Permission.photos, 'photos');
      } else {
        return _requestPermission(Permission.videos, 'videos');
      }
    }

    return _requestPermission(Permission.storage, 'storage');
  }

  void _showPermissionSnackbar(
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(label: actionLabel, onPressed: onActionPressed)
            : null,
      ),
    );
  }

  void _removeAttachmentAt(int index) {
    _newEntryMedia.removeAt(index);
    if (_newEntryMedia.isNotEmpty &&
        _attachmentPageIndex >= _newEntryMedia.length) {
      _attachmentPageIndex = _newEntryMedia.length - 1;
      if (_attachmentPageController.hasClients) {
        _attachmentPageController.jumpToPage(_attachmentPageIndex);
      }
    }
  }

  bool _hasDuplicateAttachment(Attachment newAttachment) {
    return _newEntryMedia.any((attachment) {
      return attachment.type == newAttachment.type &&
          attachment.name.toLowerCase() == newAttachment.name.toLowerCase();
    });
  }

  bool _tryAddAttachment(Attachment attachment) {
    if (_hasDuplicateAttachment(attachment)) {
      _showPermissionSnackbar(
        'An attachment with the same name and type was already added.',
      );
      return false;
    }

    setState(() {
      _newEntryMedia.add(attachment);
      _attachmentPageIndex = _newEntryMedia.length - 1;
      _isAttachmentProcessing = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_attachmentPageController.hasClients) {
        _attachmentPageController.jumpToPage(_attachmentPageIndex);
      }
    });

    return true;
  }

  Future<void> _simulateAttachmentUpload(Attachment attachment) async {
    while (attachment.uploadProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        attachment.uploadProgress = (attachment.uploadProgress + 0.12).clamp(
          0.0,
          1.0,
        );
      });
    }

    if (!mounted) return;
    setState(() {
      attachment.isUploading = false;
      _isAttachmentProcessing = _newEntryMedia.any((item) => item.isUploading);
    });
  }

  Future<void> _openAttachment(Attachment attachment) async {
    final path = attachment.path;
    if (path == null || path.isEmpty) {
      _showPermissionSnackbar('Unable to open this file.');
      return;
    }

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      _showPermissionSnackbar('Unable to open this file.');
    }
  }

  IconData _attachmentIcon(String type) {
    switch (type) {
      case 'Audio':
        return Icons.mic;
      case 'Image':
        return Icons.image;
      case 'Video':
        return Icons.videocam;
      default:
        return Icons.attach_file;
    }
  }

  String _formatAttachmentSubtitle(Attachment attachment) {
    return attachment.readableSize;
  }

  Widget _buildAttachmentCarousel(ThemeData theme) {
    return Column(
      children: [
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: SizedBox(
            height: 84,
            child: PageView.builder(
              controller: _attachmentPageController,
              onPageChanged: (index) =>
                  setState(() => _attachmentPageIndex = index),
              itemCount: _newEntryMedia.length,
              itemBuilder: (context, index) {
                final attachment = _newEntryMedia[index];
                final type = attachment.type;
                final isPendingDelete = _pendingDeleteAttachmentIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: isPendingDelete
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () {
                                        setState(() {
                                          _removeAttachmentAt(index);
                                          _pendingDeleteAttachmentIndex = null;
                                        });
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _pendingDeleteAttachmentIndex = null;
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _attachmentIcon(type),
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                attachment.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                _formatAttachmentSubtitle(attachment),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: attachment.isUploading
                                  ? SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: attachment.uploadProgress,
                                            color: theme.colorScheme.primary,
                                            backgroundColor: theme
                                                .colorScheme
                                                .secondaryContainer,
                                            strokeWidth: 3,
                                          ),
                                          Text(
                                            '${(attachment.uploadProgress * 100).round()}%',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _openAttachment(attachment),
                                          icon: Icon(
                                            Icons.remove_red_eye_outlined,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          iconSize: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _pendingDeleteAttachmentIndex =
                                                  index;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_newEntryMedia.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 24,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_newEntryMedia.length, (index) {
                    final isActive = index == _attachmentPageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.2,
                              ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SizedBox(
                  height: 56,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final hiddenWidth = constraints.maxWidth * 0.4;
                      return Stack(
                        children: [
                          AbsorbPointer(
                            absorbing: _isAttachmentProcessing,
                            child: AnimatedOpacity(
                              opacity: _isAttachmentProcessing ? 0.65 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: TabBar(
                                controller: widget.tabController,
                                onTap: (index) {
                                  if (_isAttachmentProcessing) return;
                                  switch (index) {
                                    case 2:
                                      _showMediaChoice('Audio');
                                      break;
                                    case 3:
                                      _showMediaChoice('Image');
                                      break;
                                    case 4:
                                      _showMediaChoice('Video');
                                      break;
                                    default:
                                      break;
                                  }
                                },
                                indicator: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                overlayColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                                splashBorderRadius: BorderRadius.circular(8),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                labelColor: _isAttachmentProcessing
                                    ? theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5)
                                    : theme.colorScheme.onSurfaceVariant,
                                unselectedLabelColor: _isAttachmentProcessing
                                    ? theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.45)
                                    : theme.colorScheme.onSurfaceVariant,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: widget.settings.useLargeText
                                      ? 14
                                      : 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: widget.settings.useLargeText
                                      ? 14
                                      : 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.apps, size: 20),
                                    text: 'All',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.notes, size: 20),
                                    text: 'Text',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.mic, size: 20),
                                    text: 'Audio',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.image, size: 20),
                                    text: 'Image',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.videocam, size: 20),
                                    text: 'Video',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              color: theme.colorScheme.surface,
                              width: hiddenWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Attach Media',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  widget.settings.useLargeText
                                                  ? 14
                                                  : 12,
                                              height: 1,
                                            ),
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    indent: 12,
                                    endIndent: 12,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none,
              ),
              child: NewDiaryEntryCard(
                isPrivate: _isPrivate,
                isAttachmentProcessing: _isAttachmentProcessing,
                onPrivacyChanged: (val) {
                  setState(() {
                    _isPrivate = val;
                  });
                },
                onCancel: widget.onCancel,
                onSave: (title, notes) async {
                  await widget.onSave(
                    title,
                    notes,
                    _isPrivate,
                    List.unmodifiable(_newEntryMedia),
                  );
                },
              ),
            ),
            if (_newEntryMedia.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildAttachmentCarousel(theme),
            ],
          ],
        ),
      ),
    );
  }
}
