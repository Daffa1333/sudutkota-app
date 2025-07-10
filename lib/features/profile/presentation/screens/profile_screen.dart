import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sudut_kota/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<Map<String, dynamic>>>? _mySudutFuture;
  Future<List<Map<String, dynamic>>>? _wishlistFuture;

  @override
  void initState() {
    super.initState();
    if (supabase.auth.currentUser != null) _loadData();
  }

  void _loadData() {
    if(mounted) setState(() {
      _profileFuture = _fetchProfile();
      _mySudutFuture = _fetchMySudut();
      _wishlistFuture = _fetchWishlist();
    });
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final userId = supabase.auth.currentUser!.id;
    var profile = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (profile == null) {
      await supabase.from('profiles').insert({'id': userId});
      profile = await supabase.from('profiles').select().eq('id', userId).single();
    }
    return profile;
  }

  Future<List<Map<String, dynamic>>> _fetchMySudut() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('sudut').select().eq('user_id', userId).order('tanggal_submit', ascending: false);
  }

  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    final userId = supabase.auth.currentUser!.id;
    final wishlistIdsResponse = await supabase.from('wishlist').select('sudut_id').eq('user_id', userId);
    final ids = wishlistIdsResponse.map((item) => item['sudut_id']).toList();
    if (ids.isEmpty) return [];
    return await supabase.from('sudut').select().inFilter('sudut_id', ids);
  }

  Future<void> _signOut() async { await supabase.auth.signOut(); }

  Future<void> _handleDeleteSudut(Map<String, dynamic> sudut) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus "${sudut['nama_sudut']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // PERBAIKAN: Hapus dari tabel 'sudut' terlebih dahulu.
      // Ini akan memicu 'ON DELETE CASCADE' di database, menghapus semua data terkait (suka, comment, wishlist)
      await supabase.from('sudut').delete().eq('sudut_id', sudut['sudut_id']);

      // Hapus foto dari storage SETELAH data tabel dihapus
      if (sudut['foto_utama_url'] != null) {
        final uri = Uri.parse(sudut['foto_utama_url']);
        final path = uri.pathSegments.sublist(uri.pathSegments.indexOf('photos') + 1).join('/');
        if (path.isNotEmpty) {
           await supabase.storage.from('photos').remove([path]);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sudut berhasil dihapus.')));
        _loadData();
      }
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) return const Center(child: Text("Silakan login terlebih dahulu."));
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya'), actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))]),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('Gagal memuat profil.'));
                final profile = snapshot.data!;
                return Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: profile['foto_profil_url'] != null ? NetworkImage(profile['foto_profil_url']) : null, child: profile['foto_profil_url'] == null ? const Icon(Icons.person, size: 50) : null),
                    const SizedBox(height: 16),
                    Text(profile['nama_lengkap'] ?? supabase.auth.currentUser!.email!, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(profile['bio'] ?? 'Bio belum diatur.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profil'),
                      onPressed: () async {
                        final result = await context.push<bool>('/profile/edit', extra: profile);
                        if (result == true) _loadData();
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 40),
            Text("Sudut yang Saya Bagikan", style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _mySudutFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Text('Gagal memuat daftar Sudut.');
                final sudutList = snapshot.data!;
                if (sudutList.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Anda belum membagikan Sudut apapun.")));
                return Column(
                  children: sudutList.map((sudut) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(sudut['nama_sudut']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _handleDeleteSudut(sudut),
                      )))).toList());
              },
            ),
            const Divider(height: 40),
            Text("Wishlist Saya", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _wishlistFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Text('Gagal memuat wishlist.');
                final wishlist = snapshot.data!;
                if (wishlist.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Anda belum punya wishlist.")));
                return Column(
                  children: wishlist.map((sudut) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(sudut['nama_sudut']),
                      onTap: () => context.go('/home/sudut/${sudut['sudut_id']}'),
                    ))).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}