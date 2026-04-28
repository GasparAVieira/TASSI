import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/accessibility_profile.dart';

class ProfileHeaderCard extends StatefulWidget {
  final String name;
  final String role;
  final VoidCallback onLogoutConfirm;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.role,
    required this.onLogoutConfirm,
  });

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  bool _confirmingLogout = false;

  Future<void> _showMediaChoice() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take New Image'),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Existing Image'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _requestPermission(Permission permission, String name) async {
    final status = await permission.request();
    if (!mounted) return false;
    if (status == PermissionStatus.granted) {
      return true;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (status == PermissionStatus.permanentlyDenied) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Permission denied. Open settings to enable $name.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        ),
      );
      return false;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('Allow $name permission to continue.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isIOS) {
      return _requestPermission(Permission.photos, 'photo library');
    }

    if (Platform.isAndroid) {
      return _requestPermission(Permission.photos, 'photos');
    }

    return _requestPermission(Permission.storage, 'storage');
  }

  Future<void> _captureImage() async {
    if (!await _requestPermission(Permission.camera, 'camera')) return;
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (file == null) return;

    setState(() {
      _profileImage = File(file.path);
    });
  }

  Future<void> _selectImage() async {
    if (!await _requestGalleryPermission()) return;
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _profileImage = File(file.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.role.isEmpty
        ? 'User'
        : widget.role[0].toUpperCase() + widget.role.substring(1);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                              )
                            : Icon(
                                Icons.person,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 34,
                              ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        onTap: _showMediaChoice,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_confirmingLogout)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _confirmingLogout = true),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _confirmingLogout = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onLogoutConfirm,
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatsCard extends StatelessWidget {
  final String email;
  final AccessibilityProfile accessibilityProfile;

  const ProfileStatsCard({
    super.key,
    required this.email,
    required this.accessibilityProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _ProfileStatRow(label: 'Email', value: email),
            const Divider(height: 24),
            _ProfileStatRow(
              label: 'Accessibility',
              value: accessibilityProfile.displayName,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailsCard extends StatelessWidget {
  final bool isLoading;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final PhoneNumber phoneNumber;
  final String phoneDisplayValue;
  final ValueChanged<PhoneNumber> onPhoneNumberChanged;
  final VoidCallback onToggleEditing;
  final VoidCallback onCancelEditing;

  const ProfileDetailsCard({
    super.key,
    required this.isLoading,
    required this.isEditing,
    required this.isSaving,
    required this.nameController,
    required this.phoneController,
    required this.bioController,
    required this.phoneNumber,
    required this.phoneDisplayValue,
    required this.onPhoneNumberChanged,
    required this.onToggleEditing,
    required this.onCancelEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile Details',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isEditing)
                  isSaving
                      ? SizedBox(
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: onCancelEditing,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: FilledButton(
                                onPressed: onToggleEditing,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        )
                else if (isLoading)
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (isSaving)
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: onToggleEditing,
                      child: const Text('Edit'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (!isLoading) ...[
              _buildProfileField(context, 'Full Name', nameController),
              const SizedBox(height: 12),
              _buildPhoneField(context),
              const SizedBox(height: 12),
              _buildProfileField(context, 'Biography', bioController, maxLines: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final theme = Theme.of(context);
    if (isEditing) {
      return InternationalPhoneNumberInput(
        onInputChanged: (PhoneNumber number) {
          onPhoneNumberChanged(number);
        },
        onInputValidated: (bool isValid) {
          // Optional: use the validation callback to mark invalid input if needed.
        },
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        ),
        ignoreBlank: true,
        formatInput: true,
        autoValidateMode: AutovalidateMode.onUserInteraction,
        selectorTextStyle: TextStyle(color: theme.colorScheme.onSurface),
        initialValue: phoneNumber,
        textFieldController: phoneController,
        inputDecoration: InputDecoration(
          labelText: 'Phone Number',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          counterText: '',
        ),
        keyboardType: TextInputType.phone,
        maxLength: 15,
      );
    }

    final rawValue = phoneDisplayValue.isEmpty
        ? 'Not set yet'
        : phoneDisplayValue;
    final canonicalDialCode = phoneNumber.dialCode?.trim().isNotEmpty == true
        ? (phoneNumber.dialCode!.trim().startsWith('+')
            ? phoneNumber.dialCode!.trim()
            : '+${phoneNumber.dialCode!.trim()}')
        : RegExp(r'^(\+\d+)').firstMatch(rawValue)?.group(1) ?? '';
    final rawDialCode = phoneNumber.dialCode?.trim() ?? '';
    final strippedNumber = canonicalDialCode.isNotEmpty && rawValue.startsWith(canonicalDialCode)
        ? rawValue.substring(canonicalDialCode.length)
        : rawDialCode.isNotEmpty && rawValue.startsWith(rawDialCode)
            ? rawValue.substring(rawDialCode.length)
            : rawValue;
    final nationalNumber = strippedNumber.trimLeft();
    final candidateDialCode = canonicalDialCode;
    final hasDialCode = candidateDialCode.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            children: [
              if (hasDialCode)
                TextSpan(
                  text: '$candidateDialCode ',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              TextSpan(text: nationalNumber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    if (isEditing) {
      return TextField(
        controller: controller,
        keyboardType: label == 'Phone Number' ? TextInputType.phone : TextInputType.text,
        inputFormatters: label == 'Phone Number'
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ]
            : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          controller.text.isEmpty ? 'Not set yet' : controller.text,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class ProfileActionsCard extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileActionsCard({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLogout,
            child: const Text('Log out'),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
