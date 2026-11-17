import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _routes = ['/home', '/accounts', '/cash', '/reports', '/more'];

  void _onTap(int index) {
    if (index == 2) {
      // Ortadaki + butonu - FAB action sheet
      _showAddSheet();
      return;
    }
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Hızlı İşlem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _actionTile(Icons.person_add, 'Yeni Cari Ekle', AppColors.primary, () { Navigator.pop(ctx); context.go('/accounts/new'); }),
          _actionTile(Icons.add_circle, 'Borç Ekle', AppColors.danger, () { Navigator.pop(ctx); context.go('/transactions/new?type=SALE'); }),
          _actionTile(Icons.download, 'Tahsilat Al', AppColors.success, () { Navigator.pop(ctx); context.go('/transactions/new?type=COLLECTION'); }),
          _actionTile(Icons.upload, 'Ödeme Yap', AppColors.warning, () { Navigator.pop(ctx); context.go('/transactions/new?type=PAYMENT'); }),
          _actionTile(Icons.swap_horiz, 'Transfer', AppColors.info, () { Navigator.pop(ctx); }),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.fab,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surfaceDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Ana Sayfa', 0),
              _navItem(Icons.people, 'Cariler', 1),
              const SizedBox(width: 48), // FAB boşluğu
              _navItem(Icons.account_balance_wallet, 'Kasa', 3),
              _navItem(Icons.more_horiz, 'Daha Fazla', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => _onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : AppColors.textSecondaryDark, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}

