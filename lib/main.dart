import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const TokoKitaNavigasiApp());
}

// ==========================================
// 1. DATA MODEL PRODUK & STATUS LOGIN (INTERAKTIF)
// ==========================================
class ProdukItem {
  final String id;
  final String nama;
  final String harga;
  final IconData ikon;

  const ProdukItem({required this.id, required this.nama, required this.harga, required this.ikon});
}

const List<ProdukItem> daftarProdukContoh = [
  ProdukItem(id: 'P01', nama: 'Sepatu Lari Ultralight', harga: 'Rp 750.000', ikon: Icons.directions_run),
  ProdukItem(id: 'P02', nama: 'Jam Tangan Pintar Pro', harga: 'Rp 1.200.000', ikon: Icons.watch),
  ProdukItem(id: 'P03', nama: 'Headphone Wireless Bass', harga: 'Rp 950.000', ikon: Icons.headphones),
];

// Notifier sederhana untuk memantau status login (Uji Coba Route Guard):
class StatusAuthNotifier extends ChangeNotifier {
  bool _sudahLogin = false;
  bool get sudahLogin => _sudahLogin;

  void ubahStatusLogin() {
    _sudahLogin = !_sudahLogin;
    notifyListeners(); // Beritahu GoRouter bahwa status login berubah!
  }
}

final statusAuth = StatusAuthNotifier();

// ==========================================
// 2. KONFIGURASI GOROUTER LENGKAP DENGAN ROUTE GUARD
// ==========================================
final GoRouter routerAplikasi = GoRouter(
  initialLocation: '/katalog',
  refreshListenable: statusAuth, // Dengarkan perubahan status auth
  redirect: (BuildContext context, GoRouterState state) {
    final bool isLogin = statusAuth.sudahLogin;
    final bool mauBukaVip = state.matchedLocation == '/profil/vip-club';

    // Jika pengguna belum login tapi nekat membuka /profil/vip-club:
    if (mauBukaVip && !isLogin) {
      // Satpam mengembalikan pengguna ke halaman profil:
      return '/profil';
    }
    return null; // Bebas lewat
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Cabang 1: Katalog Produk
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'katalog',
              path: '/katalog',
              builder: (context, state) => const HalamanKatalog(),
              routes: [
                GoRoute(
                  name: 'katalog-detail', // Named route standar industri
                  path: 'detail/:id',
                  builder: (context, state) {
                    final String idProduk = state.pathParameters['id']!;
                    return HalamanDetailProduk(idProduk: idProduk);
                  },
                ),
              ],
            ),
          ],
        ),

        // Cabang 2: Profil Pengguna & Uji Route Guard
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'profil',
              path: '/profil',
              builder: (context, state) => const HalamanProfil(),
              routes: [
                GoRoute(
                  name: 'vip-club',
                  path: 'vip-club', // Rute rahasia yang dijaga satpam
                  builder: (context, state) => const HalamanVipClub(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ==========================================
// 3. WIDGET APLIKASI UTAMA
// ==========================================
class TokoKitaNavigasiApp extends StatelessWidget {
  const TokoKitaNavigasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TokoKita Navigasi 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4338CA),
      ),
      routerConfig: routerAplikasi,
    );
  }
}

// ==========================================
// 4. SHELL CONTAINER DENGAN NAVIGATIONBAR
// ==========================================
class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil Saya',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. LAYAR KATALOG PRODUK
// ==========================================
class HalamanKatalog extends StatelessWidget {
  const HalamanKatalog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog TokoKita 2026', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: daftarProdukContoh.length,
        itemBuilder: (context, index) {
          final produk = daftarProdukContoh[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEEF2FF),
                child: Icon(produk.ikon, color: const Color(0xFF4338CA)),
              ),
              title: Text(produk.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(produk.harga, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Memanggil rute bernama via goNamed (aman dari perubahan URL):
                context.goNamed(
                  'katalog-detail',
                  pathParameters: {'id': produk.id},
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 6. LAYAR DETAIL PRODUK
// ==========================================
class HalamanDetailProduk extends StatelessWidget {
  final String idProduk;

  const HalamanDetailProduk({super.key, required this.idProduk});

  @override
  Widget build(BuildContext context) {
    final produk = daftarProdukContoh.firstWhere(
      (p) => p.id == idProduk,
      orElse: () => const ProdukItem(id: '404', nama: 'Barang Misterius', harga: 'Rp 0', ikon: Icons.help),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail ${produk.nama}'),
        backgroundColor: const Color(0xFF4338CA),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(produk.ikon, size: 64, color: const Color(0xFF4338CA)),
              ),
            ),
            const SizedBox(height: 20),
            Text(produk.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(produk.harga, style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('ID SKU Resmi: ${produk.id}', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Row(
              children: [
                // Tombol Kembali eksplisit mempraktikkan context.pop():
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Checkout:
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhasil menambahkan ${produk.nama} ke keranjang!')),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Beli Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. LAYAR PROFIL & SIMULASI ROUTE GUARD
// ==========================================
class HalamanProfil extends StatelessWidget {
  const HalamanProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: statusAuth,
      builder: (context, _) {
        final bool isLogin = statusAuth.sudahLogin;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Saya'),
            backgroundColor: const Color(0xFF4338CA),
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(radius: 44, child: Icon(Icons.person, size: 48)),
                const SizedBox(height: 12),
                const Text('Ahmad Fullstack Developer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('ahmad@example.com', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                // Switch Interaktif Simulasi Login:
                Card(
                  color: isLogin ? Colors.green.shade50 : Colors.amber.shade50,
                  elevation: 1,
                  child: SwitchListTile(
                    title: Text(
                      isLogin ? 'Status Akun: Sudah Login' : 'Status Akun: Belum Login',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isLogin ? Colors.green.shade900 : Colors.amber.shade900),
                    ),
                    subtitle: const Text('Ubah saklar ini untuk menguji satpam Route Guard!'),
                    value: isLogin,
                    onChanged: (_) => statusAuth.ubahStatusLogin(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Akses Halaman Terlindungi:
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isLogin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⛔ Akses Ditolak oleh Route Guard! Aktifkan saklar login di atas terlebih dahulu.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      // Mencoba membuka rute yang dijaga satpam:
                      context.go('/profil/vip-club');
                    },
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Buka Halaman Rahasia VIP Club 🌟'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 8. LAYAR VIP CLUB (AREA TERLINDUNGI)
// ==========================================
class HalamanVipClub extends StatelessWidget {
  const HalamanVipClub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Rahasia VIP Club'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium, size: 90, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Selamat Datang di VIP Club!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Hebat! Anda berhasil melewati pemeriksaan satpam Route Guard secara otomatis!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}