import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_widget.dart';
import '../widgets/filter_chips_widget.dart';
import 'login_screen.dart';
import 'detail_screen.dart';
import 'add_edit_screen.dart';

// ─── Category icon map ────────────────────────────────────────────────────────
const Map<String, IconData> _categoryIcons = {
  'All': Icons.restaurant_menu_rounded,
  'Breakfast': Icons.free_breakfast_rounded,
  'Lunch': Icons.lunch_dining_rounded,
  'Dinner': Icons.dinner_dining_rounded,
  'Snack': Icons.cookie_rounded,
  'Pasta': Icons.ramen_dining_rounded,
  'Italian': Icons.local_pizza_rounded,
  'Indian': Icons.set_meal_rounded,
  'Mexican': Icons.breakfast_dining_rounded,
  'Seafood': Icons.water_rounded,
  'Thai': Icons.local_dining_rounded,
  'Dessert': Icons.cake_rounded,
  'Salad': Icons.eco_rounded,
  'American': Icons.fastfood_rounded,
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().fetchRecipes();
    });
    _scrollController.addListener(() {
      final dir = _scrollController.position.userScrollDirection;
      if (dir.name == 'reverse' && _fabVisible) {
        setState(() => _fabVisible = false);
      } else if (dir.name == 'forward' && !_fabVisible) {
        setState(() => _fabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleUnauthorized() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RecipeProvider, AuthProvider>(
      builder: (context, recipes, auth, _) {
        if (recipes.errorMessage == '__unauthorized__') {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _handleUnauthorized());
        }

        final username = auth.currentUser['username']?.toString() ?? 'Chef';

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAF8),

          // ── FAB ────────────────────────────────────────────────────────────
          floatingActionButton: AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: _fabVisible ? Offset.zero : const Offset(0, 2.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _fabVisible ? 1.0 : 0.0,
              child: FloatingActionButton.extended(
                heroTag: 'fab_add',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditScreen()),
                  );
                  if (mounted) recipes.fetchRecipes();
                },
                backgroundColor: const Color(0xFF1A3D2B),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add Recipe',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                elevation: 6,
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          body: SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF1A3D2B),
              onRefresh: () => recipes.fetchRecipes(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Header ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _Header(
                      username: username,
                      onLogout: () async {
                        await auth.logout();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ),

                  // ── Search bar ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: _SearchBar(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {});
                          recipes.searchRecipes(val);
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() {});
                          recipes.searchRecipes('');
                        },
                      ),
                    ),
                  ),

                  // ── Category icon chips ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _CategoryRow(
                      selected: recipes.selectedCategory,
                      onTap: (cat) => recipes.filterRecipes(category: cat),
                    ),
                  ),

                  // ── Difficulty row ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _DifficultyRow(
                      selected: recipes.selectedDifficulty,
                      onTap: (diff) =>
                          recipes.filterRecipes(difficulty: diff),
                    ),
                  ),

                  // ── Section title ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            'All Recipes',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3D2B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${recipes.recipes.length}',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A3D2B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ────────────────────────────────────────────────
                  if (recipes.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ShimmerLoading(),
                    )
                  else if (recipes.errorMessage != null &&
                      recipes.errorMessage != '__unauthorized__')
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorWidget(
                        message: recipes.errorMessage!,
                        onRetry: () => recipes.fetchRecipes(),
                      ),
                    )
                  else if (recipes.recipes.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        message: 'No recipes found',
                        subtitle:
                            'Try adjusting your search or filters,\nor add your first recipe!',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final recipe = recipes.recipes[index];
                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              columnCount: 2,
                              duration: const Duration(milliseconds: 400),
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: _RecipeGridCard(
                                    recipe: recipe,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(recipe: recipe),
                                        ),
                                      );
                                      if (mounted) {
                                        recipes.fetchRecipes(silent: true);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: recipes.recipes.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Header widget ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const _Header({required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D2B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_menu_rounded,
                        color: Color(0xFFE8A838), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'EasyEats',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Logout button
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFF888888), size: 22),
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hello, $username! 👋',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What would you like\nto cook today?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.dmSans(fontSize: 15, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: 'Search recipes...',
          hintStyle:
              GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFFBBBBBB)),
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF9E9E9E)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Color(0xFF9E9E9E), size: 20),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Category icon row ────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onTap;

  const _CategoryRow({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = kCategories[index];
          final isSelected = cat == selected;
          final icon = _categoryIcons[cat] ?? Icons.restaurant_rounded;
          return GestureDetector(
            onTap: () => onTap(cat),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A3D2B)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF1A3D2B).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFFE8A838)
                        : const Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1A3D2B)
                        : const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Difficulty chip row ──────────────────────────────────────────────────────

class _DifficultyRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onTap;

  const _DifficultyRow({required this.selected, required this.onTap});

  Color _color(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFE8A838);
      case 'hard':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF1A3D2B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: kDifficulties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final diff = kDifficulties[index];
          final isSelected = diff == selected;
          final color =
              diff == 'All' ? const Color(0xFF1A3D2B) : _color(diff);
          return GestureDetector(
            onTap: () => onTap(diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFDDDAD5),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                diff,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Compact grid card ────────────────────────────────────────────────────────

class _RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeGridCard({required this.recipe, required this.onTap});

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFE8A838);
      case 'hard':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with overlay ──────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: recipe.id,
                    child: CachedNetworkImage(
                      imageUrl: recipe.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFE8E4DF),
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              color: Color(0xFFCCCCCC), size: 32),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFE8E4DF),
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              color: Color(0xFFCCCCCC), size: 32),
                        ),
                      ),
                    ),
                  ),
                  // Category tag overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.category,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info section ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Cook time badge
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 10,
                                  color: Color(0xFFE8A838)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  recipe.cookTime,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB07800),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _difficultyColor(recipe.difficulty)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _difficultyColor(recipe.difficulty),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
