import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/repositories/documents_repository.dart';
import 'package:zentrapay_application/core/repositories/user_profile_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

/// Edit-profile + Tier-2 document-upload overlay — the one place a user can
/// change their name, submit KYC details, and upload the three documents
/// that unlock sending/receiving money (see PaymentsService's tier gate).
/// Writes go through UserProfileRepository/DocumentsRepository, which
/// already implement the cache-then-async-update pattern (optimistic local
/// change, real request in the background, revert on failure).
void showEditProfileSheet(BuildContext context) {
  showAppOverlaySheet(
    context: context,
    maxHeightFraction: 0.92,
    builder: (context) => const _EditProfileContent(),
  );
}

class _EditProfileContent extends StatefulWidget {
  const _EditProfileContent();

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _postalCode;
  late final TextEditingController _occupation;
  late final TextEditingController _idType;
  late final TextEditingController _idNumber;
  DateTime? _dateOfBirth;
  bool _saving = false;
  final Map<String, bool> _uploading = {
    'id-front': false,
    'id-back': false,
    'selfie': false,
  };

  @override
  void initState() {
    super.initState();
    final user = UserProfileRepository.instance.user;
    final profile = UserProfileRepository.instance.profile;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _address1 = TextEditingController(text: profile?.addressLine1 ?? '');
    _address2 = TextEditingController(text: profile?.addressLine2 ?? '');
    _city = TextEditingController(text: profile?.cityName ?? '');
    _region = TextEditingController(text: profile?.stateOrRegion ?? '');
    _postalCode = TextEditingController(text: profile?.postalCode ?? '');
    _occupation = TextEditingController(text: profile?.occupationTitle ?? '');
    _idType = TextEditingController(text: profile?.identityDocumentType ?? '');
    _idNumber = TextEditingController(
      text: profile?.identityDocumentNumber ?? '',
    );
    _dateOfBirth = profile?.dateOfBirth;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _region.dispose();
    _postalCode.dispose();
    _occupation.dispose();
    _idType.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UserProfileRepository.instance.patchMe(
        firstName: _firstName.text.trim().isEmpty
            ? null
            : _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
      );
      await UserProfileRepository.instance.putProfile(
        dateOfBirth: _dateOfBirth,
        addressLine1: _address1.text.trim(),
        addressLine2: _address2.text.trim(),
        cityName: _city.text.trim(),
        stateOrRegion: _region.text.trim(),
        postalCode: _postalCode.text.trim(),
        occupationTitle: _occupation.text.trim(),
        identityDocumentType: _idType.text.trim(),
        identityDocumentNumber: _idNumber.text.trim(),
      );
      if (!mounted) return;
      ZentraNotifier.success(
        "Profile Updated",
        "Your changes have been saved.",
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error(
        "Update Failed",
        "Could not save your profile. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadDocument(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading[type] = true);
    try {
      await DocumentsRepository.upload(type: type, filePath: picked.path);
      await UserProfileRepository.instance.refresh();
      if (!mounted) return;
      ZentraNotifier.success(
        "Document Uploaded",
        "Your $type document was uploaded.",
      );
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error(
        "Upload Failed",
        "Could not upload the document. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _uploading[type] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ListenableBuilder(
        listenable: UserProfileRepository.instance,
        builder: (context, _) {
          final profile = UserProfileRepository.instance.profile;
          final user = UserProfileRepository.instance.user;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text("Edit Profile", style: AppTheme.headlineMedium),
                  const SizedBox(height: AppTheme.spacingSm),
                  _TierChecklist(user: user, profile: profile),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text("Name", style: AppTheme.labelLarge),
                  const SizedBox(height: AppTheme.spacingSm),
                  _field(_firstName, "First name"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_lastName, "Last name"),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text("Verification (Tier 2)", style: AppTheme.labelLarge),
                  const SizedBox(height: AppTheme.spacingSm),
                  GestureDetector(
                    onTap: _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: _field(
                        TextEditingController(
                          text: _dateOfBirth == null
                              ? ''
                              : "${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}",
                        ),
                        "Date of birth",
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(
                    _idType,
                    "ID document type (e.g. Ghana Card, NIN, National ID)",
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_idNumber, "ID document number"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_address1, "Address line 1"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_address2, "Address line 2 (optional)"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_city, "City"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_region, "State / Region"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_postalCode, "Postal code (optional)"),
                  const SizedBox(height: AppTheme.spacingLg),
                  _field(_occupation, "Occupation"),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text("Documents", style: AppTheme.labelLarge),
                  const SizedBox(height: AppTheme.spacingSm),
                  _DocumentTile(
                    label: "ID front",
                    uploaded: profile?.hasIdDocumentFront ?? false,
                    uploading: _uploading['id-front'] ?? false,
                    onTap: () => _uploadDocument('id-front'),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _DocumentTile(
                    label: "ID back",
                    uploaded: profile?.hasIdDocumentBack ?? false,
                    uploading: _uploading['id-back'] ?? false,
                    onTap: () => _uploadDocument('id-back'),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  _DocumentTile(
                    label: "Selfie",
                    uploaded: profile?.hasSelfie ?? false,
                    uploading: _uploading['selfie'] ?? false,
                    onTap: () => _uploadDocument('selfie'),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryWhite,
                              ),
                            )
                          : Text(
                              "Save Changes",
                              style: AppTheme.labelLarge.copyWith(
                                color: AppTheme.primaryWhite,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    // Return the customized TextField widget
    return TextField(
      controller: controller, // Controls the text being edited
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.textBlack.withAlpha(98),
          fontSize: 14,
        ),
        // Active state (When the user taps and focuses on the field)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.radiusMd,
          ), // Rounded border corners
          borderSide: BorderSide(
            color: AppTheme.secondaryNavy,
            width: 1,
          ), // Navy blue border when active
        ),

        // Inactive / Default state (When enabled but not focused)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.radiusMd,
          ), // Rounded border corners
          borderSide: BorderSide(
            color: AppTheme.lightGrey,
            width: 0.5,
          ), // Light grey border when inactive
        ),
        // Disabled state (When enabled: false is passed to TextField)
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.radiusMd,
          ), // Rounded border corners
          borderSide: BorderSide(
            color: AppTheme.lightGrey,
            width: 0.5,
          ), // Light grey border when disabled
        ),

        // Internal padding for the text content
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, // Horizontal inner padding
          vertical: 12, // Vertical inner padding
        ),
      ),
    );
  }
}

class _TierChecklist extends StatelessWidget {
  final AppUser? user;
  final UserProfile? profile;

  const _TierChecklist({required this.user, required this.profile});

  @override
  Widget build(BuildContext context) {
    final tier = user?.kycTier ?? 0;
    final complete = profile?.isComplete ?? false;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: complete
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.verified : Icons.info_outline,
            color: complete ? AppTheme.successGreen : AppTheme.warningOrange,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              complete
                  ? "You're Tier $tier — verified for sending & receiving money"
                  : "Fill in every field below and upload all 3 documents to reach Tier 2",
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String label;
  final bool uploaded;
  final bool uploading;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.label,
    required this.uploaded,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: uploaded ? AppTheme.successGreen : AppTheme.gray300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              uploaded ? Icons.check_circle : Icons.upload_file_outlined,
              color: uploaded ? AppTheme.successGreen : AppTheme.gray500,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(child: Text(label, style: AppTheme.bodyMedium)),
            if (uploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                uploaded ? "Uploaded" : "Tap to upload",
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
          ],
        ),
      ),
    );
  }
}
