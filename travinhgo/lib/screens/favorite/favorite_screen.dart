import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'favorite_tab/favorite_all_tab.dart';
import 'favorite_tab/favorite_destination_tab.dart';
import 'favorite_tab/favorite_local_tab.dart';
import 'favorite_tab/favorite_ocop_tab.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _selectedTab = 0;

  late final List<String> _tabs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _tabs = [l10n.all, l10n.destination, l10n.ocop, l10n.local];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface,
              automaticallyImplyLeading: false,
              title: Text(
                AppLocalizations.of(context)!.favoriteTitle,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            // Tabbar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: List.generate(
                      _tabs.length,
                          (index) => Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: _buildTab(index),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Nội dung thay đổi theo tab
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final bool isSelected = _selectedTab == index;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return FavoriteAllTab();
      case 1:
        return FavoriteDestinationTab();
      case 2:
        return FavoriteOcopTab();
      case 3:
        return FavoriteLocalTab();
      default:
        return FavoriteAllTab();
    }
  }
}
