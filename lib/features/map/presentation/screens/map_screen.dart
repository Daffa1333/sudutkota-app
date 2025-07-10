import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart'; // Import package baru
import 'package:sudut_kota/main.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Future<List<Marker>>? _markersFuture;

  @override
  void initState() {
    super.initState();
    _markersFuture = _getSudutMarkers();
  }

  Future<List<Marker>> _getSudutMarkers() async {
    try {
      final response = await supabase
          .from('sudut')
          .select()
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      final markers = response.map((sudut) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(
            sudut['latitude'] as double,
            sudut['longitude'] as double,
          ),
          child: GestureDetector(
            onTap: () {
              // Tampilkan dialog sederhana saat pin di-tap
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(sudut['nama_sudut']),
                  content: Text(sudut['deskripsi_panjang'], maxLines: 3),
                  actions: [
                    TextButton(
                      child: const Text('Tutup'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Lihat Detail'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.go('/home/sudut/${sudut['sudut_id']}');
                      },
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
          ),
        );
      }).toList();

      return markers;
    } catch (e) {
      print("Error membuat marker: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta SudutKota (OpenStreetMap)'),
      ),
      body: FutureBuilder<List<Marker>>(
        future: _markersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat peta: ${snapshot.error}'));
          }

          final markers = snapshot.data ?? [];

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-2.5489, 118.0149), // Posisi awal
              initialZoom: 5.0,
            ),
            children: [
              // Lapisan Peta
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sudut_kota',
              ),
              // Lapisan Marker (Pin)
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}