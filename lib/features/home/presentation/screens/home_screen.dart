import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sudut_kota/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _sudutFuture;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sudutFuture = _fetchSudut();
  }

  // =========================================================
  // ==           BAGIAN YANG DIPERBAIKI (SANGAT PENTING)   ==
  // =========================================================
  Future<List<Map<String, dynamic>>> _fetchSudut({String? query}) async {
    try {
      dynamic response;
      // Jika tidak ada query, ambil semua data seperti biasa
      if (query == null || query.isEmpty) {
        response = await supabase
            .from('sudut')
            .select('*, kategori(nama_kategori)')
            .order('tanggal_submit', ascending: false);
      } else {
        // Jika ADA query, panggil fungsi 'search_sudut' melalui rpc
        response = await supabase.rpc(
          'search_sudut',
          params: {'search_term': query},
        );
      }
      // Hasil dari rpc atau select sama-sama List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Gagal mengambil data Sudut');
    }
  }
  
  void _performSearch() {
    setState(() {
      _sudutFuture = _fetchSudut(query: _searchController.text.trim());
    });
  }
  // =========================================================
  // ==                AKHIR BAGIAN YANG DIPERBAIKI         ==
  // =========================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama Sudut...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {}); // Untuk menampilkan/menyembunyikan tombol clear
            },
            onSubmitted: (value) => _performSearch(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/add-sudut');
          if (result == true) {
            _performSearch();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sudutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: ${snapshot.error}')));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada Sudut yang ditemukan.'));
          }
          
          final sudutList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: sudutList.length,
            itemBuilder: (context, index) {
              final sudut = sudutList[index];
              final fotoUrl = sudut['foto_utama_url'];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () {
                    final sudutId = sudut['sudut_id'] as int;
                    context.go('/home/sudut/$sudutId');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fotoUrl != null)
                        Image.network(
                          fotoUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                          errorBuilder: (context, error, stackTrace) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 40))),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sudut['nama_sudut'], style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(sudut['deskripsi_panjang'], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}