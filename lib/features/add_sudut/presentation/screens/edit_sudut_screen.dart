import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudut_kota/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditSudutScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditSudutScreen({super.key, required this.initialData});

  @override
  State<EditSudutScreen> createState() => _EditSudutScreenState();
}

class _EditSudutScreenState extends State<EditSudutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  XFile? _imageFile;
  String? _currentImageUrl;
  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialData['nama_sudut']);
    _deskripsiController = TextEditingController(text: widget.initialData['deskripsi_panjang']);
    _latController = TextEditingController(text: widget.initialData['latitude']?.toString());
    _lngController = TextEditingController(text: widget.initialData['longitude']?.toString());
    _selectedCategoryId = widget.initialData['kategori_id'];
    _currentImageUrl = widget.initialData['foto_utama_url'];
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _updateSudut() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      String? finalImageUrl = _currentImageUrl;

      // Jika ada gambar baru, upload dan update URL
      if (_imageFile != null) {
        final userId = supabase.auth.currentUser!.id;
        final imageExtension = _imageFile!.name.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
        final path = '$userId/$fileName';
        final imageBytes = await _imageFile!.readAsBytes();

        await supabase.storage.from('photos').uploadBinary(path, imageBytes,
          fileOptions: const FileOptions(upsert: false)); // upsert false agar tidak menimpa file yg mungkin ada
        
        finalImageUrl = supabase.storage.from('photos').getPublicUrl(path);
      }

      await supabase.from('sudut').update({
        'nama_sudut': _namaController.text,
        'deskripsi_panjang': _deskripsiController.text,
        'kategori_id': _selectedCategoryId,
        'latitude': double.tryParse(_latController.text),
        'longitude': double.tryParse(_lngController.text),
        'foto_utama_url': finalImageUrl,
      }).eq('sudut_id', widget.initialData['sudut_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sudut berhasil diperbarui!')));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sudut')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview gambar
              if (_imageFile != null)
                FutureBuilder<Uint8List>(
                  future: _imageFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) return Image.memory(snapshot.data!, height: 200, fit: BoxFit.cover, width: double.infinity);
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  },
                )
              else if (_currentImageUrl != null)
                Image.network(_currentImageUrl!, height: 200, fit: BoxFit.cover, width: double.infinity),
              
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Ubah Foto Utama')),
              const SizedBox(height: 16),
              
              TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama "Sudut"'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 4, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 16),
              // Dropdown Kategori di sini... (bisa dicopy dari add_sudut_screen)
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateSudut,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}