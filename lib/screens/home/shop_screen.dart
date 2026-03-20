// lib/screens/home/shop_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _coins = 500;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Shop', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('$_coins',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, color: AppColors.accent)),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.accent,
          labelStyle: GoogleFonts.fredoka(fontSize: 13),
          tabs: const [
            Tab(text: '🎨 Themes'),
            Tab(text: '🎲 Dice'),
            Tab(text: '🃏 Tokens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildThemesTab(),
          _buildDiceTab(),
          _buildTokensTab(),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    final items = [
      _ShopItem(emoji: '🎮', name: 'Classic', price: 0, owned: true),
      _ShopItem(emoji: '💜', name: 'Neon City', price: 200),
      _ShopItem(emoji: '🚀', name: 'Space', price: 300),
      _ShopItem(emoji: '🌿', name: 'Forest', price: 250),
      _ShopItem(emoji: '🪔', name: 'Diwali', price: 350),
      _ShopItem(emoji: '❄️', name: 'Ice Kingdom', price: 500),
      _ShopItem(emoji: '🔥', name: 'Lava World', price: 500),
      _ShopItem(emoji: '🌸', name: 'Sakura', price: 400),
    ];
    return _ShopGrid(items: items, coins: _coins, onBuy: _onBuy);
  }

  Widget _buildDiceTab() {
    final items = [
      _ShopItem(emoji: '🎲', name: 'Classic Dice', price: 0, owned: true),
      _ShopItem(emoji: '💎', name: 'Crystal Dice', price: 150),
      _ShopItem(emoji: '🔥', name: 'Fire Dice', price: 200),
      _ShopItem(emoji: '⚡', name: 'Lightning', price: 250),
      _ShopItem(emoji: '🌙', name: 'Moon Dice', price: 300),
      _ShopItem(emoji: '👑', name: 'Royal Dice', price: 400),
    ];
    return _ShopGrid(items: items, coins: _coins, onBuy: _onBuy);
  }

  Widget _buildTokensTab() {
    final items = [
      _ShopItem(emoji: '⭕', name: 'Classic', price: 0, owned: true),
      _ShopItem(emoji: '⭐', name: 'Star Tokens', price: 150),
      _ShopItem(emoji: '💎', name: 'Diamond', price: 250),
      _ShopItem(emoji: '🐉', name: 'Dragon', price: 350),
      _ShopItem(emoji: '👑', name: 'Crown', price: 400),
      _ShopItem(emoji: '🦋', name: 'Butterfly', price: 200),
    ];
    return _ShopGrid(items: items, coins: _coins, onBuy: _onBuy);
  }

  void _onBuy(_ShopItem item) {
    if (_coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not enough coins! Need ${item.price} 🪙',
            style: GoogleFonts.nunito(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _coins -= item.price);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.emoji} ${item.name} unlocked!',
          style: GoogleFonts.nunito(color: Colors.white)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _ShopItem {
  final String emoji;
  final String name;
  final int price;
  final bool owned;
  _ShopItem(
      {required this.emoji,
      required this.name,
      required this.price,
      this.owned = false});
}

class _ShopGrid extends StatelessWidget {
  final List<_ShopItem> items;
  final int coins;
  final void Function(_ShopItem) onBuy;
  const _ShopGrid(
      {required this.items, required this.coins, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final canAfford = coins >= item.price;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: item.owned
                ? AppColors.greenPlayer.withValues(alpha: 0.08)
                : AppColors.darkCard,
            border: Border.all(
              color: item.owned
                  ? AppColors.greenPlayer.withValues(alpha: 0.4)
                  : AppColors.darkBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 6),
              Text(item.name,
                  style: GoogleFonts.fredoka(
                      fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              item.owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenPlayer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('✅ Owned',
                          style: GoogleFonts.nunito(
                              fontSize: 12, color: AppColors.greenPlayer)),
                    )
                  : GestureDetector(
                      onTap: () => onBuy(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canAfford
                                ? AppColors.accent.withValues(alpha: 0.5)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text('${item.price}',
                                style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    color: canAfford
                                        ? AppColors.accent
                                        : Colors.white38)),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ).animate(delay: (i * 40).ms).fadeIn().scale(
            begin: const Offset(0.9, 0.9));
      },
    );
  }
}
