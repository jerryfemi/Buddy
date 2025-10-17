import 'dart:io';

import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/widgets/my_sliver_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../firebase/service/storage_service.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _uploadImageAndSaveProfile() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final storageService = StorageService();

    try {
      final currentProfile = ref.read(userProfileProvider).value;
      final oldPhotoUrl = currentProfile?['photoUrl'] as String?;

      //  upload with extension + cache-busting URL
      final freshPhotoUrl = await storageService.uploadProfileImage(
        uid,
        _imageFile!,
      );

      //  Update Firestore with fresh URL
      await ref.read(userFirestoreProvider).updateProfile(uid, {
        'photoUrl': freshPhotoUrl,
        'updatedAt': DateTime.now(),
      });

      //  update the UI,
      ref.read(userProfileProvider.notifier).updateProfile({
        ...?currentProfile,
        'photoUrl': freshPhotoUrl,
        'updatedAt': DateTime.now(),
      });
      // refresh the UI
      setState(() => _imageFile = null);


      //  delete old image only after success
      if (oldPhotoUrl != null &&
          oldPhotoUrl.isNotEmpty &&
          oldPhotoUrl != freshPhotoUrl &&
          oldPhotoUrl.contains('user_profiles')) {
        await storageService.deleteProfileImage(oldPhotoUrl);
      }

      _showSnackBar("Profile picture updated successfully!");
    } catch (e, st) {
      debugPrintStack(label: 'Upload failed', stackTrace: st);
      _showSnackBar("Error uploading image: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const _NoProfileView();

          if (_nameController.text != (profile['displayName'] ?? '')) {
            _nameController.text = profile['displayName'] ?? '';
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              MySliverAppBar(
                title: 'Profile',
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.exit_to_app,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ProfileContent(
                  profile: profile,
                  nameController: _nameController,
                  imageFile: _imageFile,
                  isUploading: _isUploading,
                  onPickImage: _pickImage,
                  onUploadImage: _uploadImageAndSaveProfile,
                  onSaveProfile: () async {
                    final uid = user!.uid;
                    try {
                      await ref.read(userFirestoreProvider).updateProfile(uid, {
                        'displayName': _nameController.text.trim(),
                        'updatedAt': DateTime.now(),
                      });
                      _showSnackBar("Profile updated");
                    } catch (e) {
                      _showSnackBar("Error updating profile: $e");
                    }
                  },
                  user: user,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: "Error loading profile: $e",
          onRetry: () => ref.refresh(userProfileProvider),
        ),
      ),
    );
  }
}

// -------------------- EXTRACTED WIDGETS --------------------

class _NoProfileView extends StatelessWidget {
  const _NoProfileView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64.sp,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            "No profile found",
            style: TextStyle(
              fontSize: context.adaptSize(18.sp, tab: 16.sp),
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Please try signing out and signing back in",
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16.h),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> profile;
  final TextEditingController nameController;
  final File? imageFile;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onUploadImage;
  final VoidCallback onSaveProfile;
  final User? user;

  const _ProfileContent({
    required this.profile,
    required this.nameController,
    required this.imageFile,
    required this.isUploading,
    required this.onPickImage,
    required this.onUploadImage,
    required this.onSaveProfile,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child:
          Column(
                children: [
                  _AvatarSection(
                        profile: profile,
                        imageFile: imageFile,
                        onPickImage: onPickImage,
                      )
                      .animate()
                      .slide(
                        begin: Offset(1, 0),
                        end: Offset.zero,
                        curve: Curves.easeInOut,
                      )
                      .fade(duration: 1.seconds),
                  SizedBox(height: 20.h),
                  _EmailTile(
                    email: profile['email'] ?? user?.email ?? 'No email',
                  ),
                  SizedBox(height: 20.h),
                  TextFormField(
                    controller: nameController,
                    decoration: _decoration(context, 'Username'),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: onSaveProfile,
                      child: const Text("Save Changes"),
                    ),
                  ),
                  if (imageFile != null) ...[
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : onUploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: isUploading
                            ? const _UploadingIndicator()
                            : const Text("Upload Profile Picture"),
                      ),
                    ),
                  ],
                ],
              )
              .animate()
              .fade(duration: 1.seconds)
              .slide(
                begin: Offset(0, 0.02),
                end: Offset.zero,
                curve: Curves.easeInOut,
              ),
    );
  }
}

InputDecoration _decoration(BuildContext context, String hint) {
  return InputDecoration(
    filled: true,
    fillColor: Theme.of(context).colorScheme.secondary,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.secondary,
        width: 2,
      ),
    ),
    hintText: hint,
    labelText: 'Username',
    prefixIcon: Icon(
      Icons.person,
      color: Theme.of(context).colorScheme.tertiary,
    ),
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.secondary,
        width: 2,
      ),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _AvatarSection extends StatelessWidget {
  final Map<String, dynamic> profile;
  final File? imageFile;
  final VoidCallback onPickImage;

  const _AvatarSection({
    required this.profile,
    required this.imageFile,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          key: ValueKey(profile['photoUrl']),
          radius: 50.r,
          backgroundImage: imageFile != null
              ? FileImage(imageFile!)
              : (profile['photoUrl']?.isNotEmpty ?? false)
              ? CachedNetworkImageProvider(profile['photoUrl'])
              : null,
          child: (profile['photoUrl'] == null && imageFile == null)
              ? Icon(
                  Icons.person,
                  size: 50.r,
                  color: Theme.of(context).colorScheme.tertiary,
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 16.r,
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.white, size: 16.sp),
              onPressed: onPickImage,
              constraints: BoxConstraints(minHeight: 32.h, minWidth: 32.w),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailTile extends StatelessWidget {
  final String email;

  const _EmailTile({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.email, color: Theme.of(context).colorScheme.tertiary),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              email,
              style: TextStyle(fontSize: context.adaptSize(16.sp, tab: 12.sp)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16.w,
          height: 16.h,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8.w),
        Text("Uploading..."),
      ],
    );
  }
}
