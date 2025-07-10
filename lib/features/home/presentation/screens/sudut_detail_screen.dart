import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sudut_kota/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SudutDetailScreen extends StatefulWidget {
  final int sudutId;
  const SudutDetailScreen({super.key, required this.sudutId});

  @override
  State<SudutDetailScreen> createState() => _SudutDetailScreenState();
}

class _SudutDetailScreenState extends State<SudutDetailScreen> {
  late Future<Map<String, dynamic>> _sudutFuture;
  late final Stream<List<Map<String, dynamic>>> _komentarStream;
  final _komentarController = TextEditingController();

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = true;
  bool _isInWishlist = false;
  bool _isLoadingWishlist = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if(mounted) {
      setState(() {
        _sudutFuture = _fetchSudutDetail();
        _komentarStream = supabase.from('komentar').stream(primaryKey: ['id']).eq('sudut_id', widget.sudutId).order('created_at', ascending: false);
      });
    }
  }
  
  @override
  void dispose() { _komentarController.dispose(); super.dispose(); }

  Future<Map<String, dynamic>> _fetchSudutDetail() async {
    final response = await supabase.from('sudut').select('*, kategori(nama_kategori)').eq('sudut_id', widget.sudutId).single();
    _getInitialStatus(response['jumlah_suka']);
    return response;
  }

  Future<void> _getInitialStatus(int initialLikeCount) async {
    final userId = supabase.auth.currentUser!.id;
    final [likeRes, wishlistRes] = await Future.wait([
      supabase.from('suka').select('id').eq('sudut_id', widget.sudutId).eq('user_id', userId),
      supabase.from('wishlist').select('id').eq('sudut_id', widget.sudutId).eq('user_id', userId),
    ]);
    if(mounted) setState(() {
      _isLiked = likeRes.isNotEmpty;
      _likeCount = initialLikeCount;
      _isInWishlist = wishlistRes.isNotEmpty;
      _isLoadingLike = false;
      _isLoadingWishlist = false;
    });
  }

  Future<void> _toggleLike() async {
    final userId = supabase.auth.currentUser!.id;
    setState(() { _isLiked = !_isLiked; _isLiked ? _likeCount++ : _likeCount--; });
    if (_isLiked) {
      await supabase.from('suka').insert({'sudut_id': widget.sudutId, 'user_id': userId});
      await supabase.rpc('increment', params: {'x': 1, 'row_id': widget.sudutId});
    } else {
      await supabase.from('suka').delete().match({'sudut_id': widget.sudutId, 'user_id': userId});
      await supabase.rpc('increment', params: {'x': -1, 'row_id': widget.sudutId});
    }
  }
  
  Future<void> _toggleWishlist() async {
    final userId = supabase.auth.currentUser!.id;
    setState(() { _isInWishlist = !_isInWishlist; });
    if (_isInWishlist) {
      await supabase.from('wishlist').insert({'sudut_id': widget.sudutId, 'user_id': userId});
    } else {
      await supabase.from('wishlist').delete().match({'sudut_id': widget.sudutId, 'user_id': userId});
    }
  }

  Future<void> _kirimKomentar() async {
    final isiKomentar = _komentarController.text.trim();
    if (isiKomentar.isEmpty) return;
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('komentar').insert({
      'sudut_id': widget.sudutId,
      'user_id': userId,
      'isi_komentar': isiKomentar,
    });
    _komentarController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sudut')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _sudutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: Text('Data tidak ditemukan.'));

          final sudut = snapshot.data!;
          final fotoUrl = sudut['foto_utama_url'];
          final namaKategori = (sudut['kategori'] as Map?)?['nama_kategori'] ?? 'Tanpa Kategori';
          final lat = sudut['latitude'] as double?;
          final lng = sudut['longitude'] as double?;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (fotoUrl != null) Image.network(fotoUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(sudut['nama_sudut'], style: Theme.of(context).textTheme.headlineMedium)),
                                Row(
                                  children: [
                                    if (_isLoadingLike) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                    else IconButton(icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border), color: _isLiked ? Colors.red : null, onPressed: _toggleLike),
                                    Text(_likeCount.toString()),
                                    const SizedBox(width: 8),
                                    if (_isLoadingWishlist) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                    else IconButton(icon: Icon(_isInWishlist ? Icons.bookmark : Icons.bookmark_border), color: _isInWishlist ? Theme.of(context).primaryColor : null, onPressed: _toggleWishlist),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Chip(label: Text(namaKategori), backgroundColor: Theme.of(context).colorScheme.secondaryContainer),
                            const SizedBox(height: 16),
                            Text(sudut['deskripsi_panjang'], style: Theme.of(context).textTheme.bodyLarge),
                            Builder(
                              builder: (context) {
                                final isOwner = supabase.auth.currentUser!.id == sudut['user_id'];
                                if (isOwner) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Center(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.edit_note),
                                        label: const Text('Edit Sudut Ini'),
                                        onPressed: () async {
                                          final result = await context.push<bool>('/home/sudut/${widget.sudutId}/edit', extra: sudut);
                                          if (result == true) { _loadData(); }
                                        },
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            if (lat != null && lng != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 40),
                                    Text("Lokasi", style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 200,
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: LatLng(lat, lng),
                                          initialZoom: 15.0,
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(point: LatLng(lat, lng), child: const Icon(Icons.location_pin, color: Colors.red, size: 40)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 40),
                            Text("Komentar", style: Theme.of(context).textTheme.titleLarge),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _komentarStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Jadilah yang pertama berkomentar!")));
                                final komentarList = snapshot.data!;
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: komentarList.length,
                                  itemBuilder: (context, index) {
                                    final komentar = komentarList[index];
                                    return ListTile(
                                      leading: const CircleAvatar(child: Icon(Icons.person)),
                                      title: Text(komentar['isi_komentar']),
                                      subtitle: Text(TimeOfDay.fromDateTime(DateTime.parse(komentar['created_at'])).format(context)),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _komentarController, decoration: const InputDecoration(hintText: 'Tulis komentar...', border: OutlineInputBorder()))),
                    IconButton(icon: const Icon(Icons.send), onPressed: _kirimKomentar),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}