import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudut_kota/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _bioController;
  bool _isLoading = false;
  XFile? _imageFile;
  String? _currentImageUrl; // State untuk melacak URL gambar saat ini

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialProfile['nama_lengkap']);
    _bioController = TextEditingController(text: widget.initialProfile['bio']);
    _currentImageUrl = widget.initialProfile['foto_profil_url'];
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  // Fungsi baru untuk menghapus foto
  Future<void> _deleteProfilePicture() async {
    if (_currentImageUrl == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil?'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uri = Uri.parse(_currentImageUrl!);
      final path = uri.pathSegments.length > 2 ? uri.pathSegments.sublist(2).join('/') : null;
      if (path != null) {
        await supabase.storage.from('photos').remove([path]);
      }
      setState(() {
        _currentImageUrl = null;
        _imageFile = null; // Hapus juga preview jika ada
      });
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus foto: $e")));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      String? finalImageUrl = _currentImageUrl;

      if (_imageFile != null) {
        final imageExtension = _imageFile!.name.split('.').last.toLowerCase();
        final path = '$userId/profile.$imageExtension'; 
        final imageBytes = await _imageFile!.readAsBytes();
        
        await supabase.storage.from('photos').uploadBinary(
          path, imageBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        finalImageUrl = '${supabase.storage.from('photos').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      await supabase.from('profiles').update({
        'nama_lengkap': _namaController.text,
        'bio': _bioController.text,
        'foto_profil_url': finalImageUrl, // Gunakan URL final
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
        context.pop(true);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    if (_imageFile != null)
                      FutureBuilder<Uint8List>(
                        future: _imageFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) return CircleAvatar(radius: 60, backgroundImage: MemoryImage(snapshot.data!));
                          return const CircleAvatar(radius: 60, child: CircularProgressIndicator());
                        },
                      )
                    else
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null,
                        child: _currentImageUrl == null ? const Icon(Icons.person, size: 60) : null,
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(icon: const Icon(Icons.camera_alt), onPressed: _pickImage),
                    ),
                    // Tombol Hapus Foto Baru
                    if (_currentImageUrl != null || _imageFile != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: IconButton.filled(
                          icon: const Icon(Icons.delete),
                          onPressed: _deleteProfilePicture,
                          style: IconButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Lengkap'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _bioController, decoration: const InputDecoration(labelText: 'Bio Singkat'), maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading ? null : _updateProfile, child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Perubahan')),
            ],
          ),
        ),
      ),
    );
  }
}