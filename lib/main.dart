import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

// Import repositories
import 'data/repositories/recipe_repository.dart';

// Import blocs/cubits
import 'features/home/bloc/home_bloc.dart';
import 'features/auth/cubit/auth_cubit.dart';

// Import screens
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/shopping_list_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/scan_food/screens/scan_food_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Theme Cubit
        BlocProvider(create: (context) => ThemeCubit()),

        // Auth Cubit
        BlocProvider(create: (context) => AuthCubit()..checkAuthStatus()),

        // Repository Provider
        RepositoryProvider(create: (context) => RecipeRepository()),

        // Home BLoC
        BlocProvider(
          create: (context) =>
              HomeBloc(repository: context.read<RecipeRepository>())
                ..add(LoadHomeRecipes()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Find My Food',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            // home: const MainNavigationScreen(), // Bypassed Login
          );
        },
      ),
    );
  }
}

// Auth Wrapper - decides which screen to show
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const SplashScreen();
        }

        if (state is AuthAuthenticated) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// Simple Splash Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Text('🍳', style: TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Find My Food',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Navigation Screen
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ScanFoodScreen(),
    const ShoppingListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    // Filter screens and destinations based on authentication
    List<Widget> currentScreens = [const HomeScreen()];
    List<NavigationDestination> currentDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(
          Icons.restaurant_menu,
          color: AppTheme.primaryOrange,
        ),
        label: 'เมนู',
      ),
    ];

    if (isAuthenticated) {
      currentScreens.add(const ScanFoodScreen());
      currentDestinations.add(
        NavigationDestination(
          icon: const Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(
            Icons.document_scanner,
            color: AppTheme.primaryOrange,
          ),
          label: 'สแกน',
        ),
      );
    }

    // Add Shopping List and Profile (Always show for now? Or hide Shopping List too?)
    // Assuming only Scan and Add were requested to be hidden.
    // Keeping Shopping List and Profile for now as user only specified Scan/Add.
    currentScreens.add(const ShoppingListScreen());
    currentDestinations.add(
      NavigationDestination(
        icon: const Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
        label: 'จ่ายตลาด',
      ),
    );

    currentScreens.add(const ProfileScreen());
    currentDestinations.add(
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppTheme.primaryOrange),
        label: 'โปรไฟล์',
      ),
    );

    // Ensure index is valid
    if (_currentIndex >= currentScreens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: currentScreens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: isDarkMode
                ? const Color(0xFF16213E)
                : Colors.white,
            indicatorColor: AppTheme.primaryOrange.withOpacity(0.2),
            destinations: currentDestinations,
          ),
        ),
      ),
    );
  }
}
