import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/storage_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _profiles = ProfileRepository();
  final _storage = StorageRepository();
  final _picker = ImagePicker();
  late final Future<UserModel?> _profile;
  XFile? _selectedImage;
  Uint8List? _previewBytes;
  String _profileImageUrl = '';
  bool _loading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _email.text = user?.email ?? '';
    _profile = _loadProfile(user?.uid);
  }

  Future<UserModel?> _loadProfile(String? uid) async {
    if (uid == null) return null;
    final profile = await _profiles.getProfile(uid);
    if (profile != null && mounted) {
      _name.text = profile.name;
      _phone.text = profile.phone;
      _location.text = profile.location;
      _profileImageUrl = profile.profileImage;
    }
    return profile;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sign in to update your profile.');
      final imageUrl = _selectedImage == null
          ? null
          : await _storage.uploadProfileImage(
              uid: user.uid,
              image: _selectedImage!,
              onProgress: (progress) {
                if (mounted) setState(() => _uploadProgress = progress);
              },
            );
      await _profiles.updateProfile(
        name: _name.text,
        phone: _phone.text,
        location: _location.text,
        profileImage: imageUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length >= 5 * 1024 * 1024) {
        throw ArgumentError('Choose a profile image smaller than 5 MB.');
      }
      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _previewBytes = bytes;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select image: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: FutureBuilder<UserModel?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load your profile. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) {
            return const Center(
              child: Text(
                  'Your profile could not be found. Please sign in again.'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.black12,
                        child: ClipOval(
                          child: _previewBytes != null
                              ? Image.memory(
                                  _previewBytes!,
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                )
                              : _profileImageUrl.isNotEmpty
                                  ? Image.network(
                                      _profileImageUrl,
                                      width: 84,
                                      height: 84,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Icon(Icons.person, size: 40),
                                    )
                                  : const Icon(Icons.person, size: 40),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _loading ? null : _pickImage,
                          tooltip: 'Choose profile photo',
                          icon: const Icon(Icons.camera_alt, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedImage != null && _loading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(value: _uploadProgress),
                  ),
                CustomTextField(
                  label: 'Name',
                  hint: 'Name',
                  controller: _name,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                CustomTextField(
                  label: 'Email',
                  hint: 'Email',
                  controller: _email,
                  readOnly: true,
                ),
                CustomTextField(
                  label: 'Phone',
                  hint: 'Phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                ),
                CustomTextField(
                  label: 'Location',
                  hint: 'Location',
                  controller: _location,
                ),
                CustomButton(
                  text: _loading
                      ? _selectedImage == null
                          ? 'Saving...'
                          : 'Uploading ${(100 * _uploadProgress).round()}%'
                      : 'Save Changes',
                  onPressed: _loading ? null : _save,
                  loading: _loading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
