import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/recipe_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// ─── Entry point ────────────────────────────────────────────────────────────
// IMPORTANT: WidgetsFlutterBinding.ensureInitialized() MUST be called before
// any async work (SharedPreferences, etc.) is done before runApp().
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load the AuthProvider so we know login state before the first frame.
  final authProvider = AuthProvider();
  await authProvider.checkAuthStatus();

  runApp(EasyEatsApp(authProvider: authProvider));
}

class EasyEatsApp extends StatelessWidget {
  final AuthProvider authProvider;

  const EasyEatsApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Reuse the pre-loaded AuthProvider instance — do NOT create a new one
        // here, otherwise the already-resolved auth state would be thrown away.
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: MaterialApp(
        title: 'EasyEats',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3D2B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.dmSansTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFFAFAF8),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1A3D2B),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        home: const _SplashRouter(),
      ),
    );
  }
}

// ─── Splash / Router ─────────────────────────────────────────────────────────
// This widget shows the animated splash screen, then navigates IMPERATIVELY
// (not declaratively) to HomeScreen or LoginScreen. Imperative navigation
// removes _SplashRouter from the active widget tree entirely, preventing any
// future rebuild from it from overriding the current screen.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Show the splash for a minimum of 1.4 s so the animation plays fully.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Auth state was resolved BEFORE runApp() in main(), so this read is
    // synchronous and instant — no second async check needed here.
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    // Navigate imperatively so _SplashRouter is fully replaced and can never
    // interfere with the destination screen's state again.
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            isLoggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3D2B),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A838),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8A838).withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'EasyEats',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover · Cook · Enjoy',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: const Color(0xFFE8A838).withValues(alpha: 0.7),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
