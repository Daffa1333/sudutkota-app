import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudut_kota/main.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

class AddSudutScreen extends StatefulWidget {
  const AddSudutScreen({super.key});

  @override
  State<AddSudutScreen> createState() => _AddSudutScreenState();
}

class _AddSudutScreenState extends State<AddSudutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  int? _selectedCategoryId;
  XFile? _imageFile;
  bool _isLoading = false;

  Future<void> _submitSudut() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom dan foto wajib diisi.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final imageExtension = _imageFile!.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
      final path = '$userId/$fileName';
      final imageBytes = await _imageFile!.readAsBytes();
      await supabase.storage.from('photos').uploadBinary(path, imageBytes);
      final imageUrl = supabase.storage.from('photos').getPublicUrl(path);

      await supabase.from('sudut').insert({
        'user_id': userId,
        'nama_sudut': _namaController.text,
        'deskripsi_panjang': _deskripsiController.text,
        'kategori_id': _selectedCategoryId,
        'foto_utama_url': imageUrl,
        'latitude': double.tryParse(_latController.text),
        'longitude': double.tryParse(_lngController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sudut baru berhasil ditambahkan!')));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Gagal: $e')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
  
  Future<List<Map<String, dynamic>>> _fetchCategories() async { return await supabase.from('kategori').select(); }
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if(image != null) setState(() => _imageFile = image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Sudut Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama "Sudut"'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 4, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),
              
              // Opsi Pilih di Peta
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pilih Lokasi di Peta (Direkomendasikan)'),
                onPressed: () async {
                  final result = await context.push<LatLng>('/pick-location');
                  if (result != null) {
                    setState(() {
                      _latController.text = result.latitude.toString();
                      _lngController.text = result.longitude.toString();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              const Center(child: Text("ATAU")),
              const SizedBox(height: 8),

              // Input Manual Latitude & Longitude
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude (manual)'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude (manual)'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 16),

              // ... sisa UI sama
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCategories(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final categories = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    items: categories.map((c) => DropdownMenuItem<int>(value: c['kategori_id'], child: Text(c['nama_kategori']))).toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    decoration: const InputDecoration(labelText: 'Pilih Kategori'),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Pilih Foto Utama')),
              const SizedBox(height: 8),
              if (_imageFile != null)
                FutureBuilder<Uint8List>(
                  future: _imageFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return Image.memory(snapshot.data!, height: 200, fit: BoxFit.cover, width: double.infinity);
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading ? null : _submitSudut, child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Sudut')),
            ],
          ),
        ),
      ),
    );
  }
}