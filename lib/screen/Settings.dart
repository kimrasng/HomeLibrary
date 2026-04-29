import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const String _barcodeAutoAddKey = 'barcodeAutoAdd';
  bool _barcodeAutoAdd = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _barcodeAutoAdd = prefs.getBool(_barcodeAutoAddKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveBarcodeAutoAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_barcodeAutoAddKey, value);
    setState(() {
      _barcodeAutoAdd = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar.medium(
                  title: const Text('설정'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: 8),

                      // ── Barcode section header ──
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 8,
                        ),
                        child: Text(
                          '바코드',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                      // ── Barcode settings card ──
                      Card.filled(
                        child: SwitchListTile(
                          title: Text(
                            '바코드 자동 추가',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '스캔 후 확인 없이 바로 추가',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: _barcodeAutoAdd,
                          onChanged: _saveBarcodeAutoAdd,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── App info section header ──
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 8,
                        ),
                        child: Text(
                          '앱 정보',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                      // ── App info card ──
                      Card.filled(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: const Text('홈 서재'),
                          subtitle: const Text('버전 1.0.0'),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
