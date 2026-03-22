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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text('PREMIUM SHOP',
            style: GoogleFonts.fredoka(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('$_coins',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7B85FF)]),
                boxShadow: [
                   BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
              labelStyle: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'THEMES'),
                Tab(text: 'DICE'),
                Tab(text: 'TOKENS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        physics: const BouncingScrollPhysics(),
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
            style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
      return;
    }
    setState(() => _coins -= item.price);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.emoji} ${item.name} unlocked!',
          style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.greenPlayer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final canAfford = coins >= item.price;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 6)),
            ],
            border: item.owned
                ? Border.all(color: AppColors.greenPlayer.withValues(alpha: 0.2), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 40)).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                ),
              ),
              const SizedBox(height: 12),
              Text(item.name.toUpperCase(),
                  style: GoogleFonts.fredoka(
                      fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              item.owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greenPlayer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('OWNED',
                          style: GoogleFonts.fredoka(
                              fontSize: 11, color: AppColors.greenPlayer, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    )
                  : IntrinsicWidth(
                    child: GestureDetector(
                        onTap: () => onBuy(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.textDark.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: canAfford
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text('${item.price}',
                                  style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      color: canAfford
                                          ? AppColors.primary
                                          : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.2),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ),
            ],
          ),
        ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }
}
