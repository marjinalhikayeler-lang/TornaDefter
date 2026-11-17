import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

/// Tema renk seçici provider
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(AppColors.primary) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('accent_color');
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.value);
  }
}

/// Özel Renk Seçici Ekranı
class ThemeColorPickerScreen extends ConsumerWidget {
  const ThemeColorPickerScreen({super.key});

  static const List<_ColorOption> _colors = [
    _ColorOption('Okyanus Mavisi', Color(0xFF1E88E5)),
    _ColorOption('Gece Mavisi', Color(0xFF1E3A5F)),
    _ColorOption('Turkuaz', Color(0xFF00BCD4)),
    _ColorOption('Yeşil', Color(0xFF4CAF50)),
    _ColorOption('Zümrüt', Color(0xFF009688)),
    _ColorOption('Turuncu', Color(0xFFFF9800)),
    _ColorOption('Kırmızı', Color(0xFFE53935)),
    _ColorOption('Pembe', Color(0xFFE91E63)),
    _ColorOption('Mor', Color(0xFF9C27B0)),
    _ColorOption('Lacivert', Color(0xFF283593)),
    _ColorOption('Kahverengi', Color(0xFF795548)),
    _ColorOption('Gri Mavi', Color(0xFF607D8B)),
    _ColorOption('İndigo', Color(0xFF3F51B5)),
    _ColorOption('Amber', Color(0xFFFFC107)),
    _ColorOption('Lime', Color(0xFF8BC34A)),
    _ColorOption('Cyan', Color(0xFF00ACC1)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor = ref.watch(accentColorProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Tema Rengi'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: Column(
        children: [
          // Önizleme
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Önizleme', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PreviewButton(color: currentColor, label: 'Birincil'),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Etiket', style: TextStyle(color: currentColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: currentColor,
                      radius: 18,
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(currentColor),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          // Renk grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final option = _colors[index];
                final isSelected = currentColor.value == option.color.value;

                return GestureDetector(
                  onTap: () => ref.read(accentColorProvider.notifier).setColor(option.color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: option.color,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: option.color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          option.name,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  final Color color;
  final String label;
  const _PreviewButton({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption(this.name, this.color);
}

