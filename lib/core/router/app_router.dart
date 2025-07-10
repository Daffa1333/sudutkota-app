import 'package:go_router/go_router.dart';
import 'package:sudut_kota/core/widgets/main_shell.dart';
import 'package:sudut_kota/features/add_sudut/presentation/screens/add_sudut_screen.dart';
import 'package:sudut_kota/features/add_sudut/presentation/screens/edit_sudut_screen.dart';
import 'package:sudut_kota/features/auth/presentation/screens/login_screen.dart';
import 'package:sudut_kota/features/auth/presentation/screens/register_screen.dart';
import 'package:sudut_kota/features/home/presentation/screens/home_screen.dart';
import 'package:sudut_kota/features/home/presentation/screens/sudut_detail_screen.dart';
import 'package:sudut_kota/features/map/presentation/screens/location_picker_screen.dart'; // Import Baru
import 'package:sudut_kota/features/map/presentation/screens/map_screen.dart';
import 'package:sudut_kota/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sudut_kota/features/profile/presentation/screens/profile_screen.dart';
import 'package:sudut_kota/features/splash/presentation/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Rute di luar Shell (tanpa BottomNavBar)
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/add-sudut', builder: (context, state) => const AddSudutScreen()),
    // Rute Baru untuk Pemilih Lokasi
    GoRoute(path: '/pick-location', builder: (context, state) => const LocationPickerScreen()),

    // Rute di dalam Shell
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'sudut/:id',
              builder: (context, state) {
                final sudutId = int.parse(state.pathParameters['id']!);
                return SudutDetailScreen(sudutId: sudutId);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final data = state.extra as Map<String, dynamic>;
                    return EditSudutScreen(initialData: data);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final profileData = state.extra as Map<String, dynamic>;
                return EditProfileScreen(initialProfile: profileData);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapScreen(),
        ),
      ],
    ),
  ],
);