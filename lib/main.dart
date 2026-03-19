import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import core
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/navigation/navigation_cubit.dart';
import 'core/utils/responsive_helper.dart';

// Import repositories
import 'data/repositories/recipe_repository.dart';

// Import blocs/cubits
import 'features/home/bloc/home_bloc.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/notification/bloc/notification_bloc.dart';
import 'features/notification/services/notification_api_service.dart';

// Import screens
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/shopping_list_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/google_register_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/scan_food/screens/scan_food_screen.dart';
import 'features/notification/services/notification_service.dart';
import 'features/auth/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    // Firebase initialization might fail if config is missing, silting it as requested
  }

  await initializeDateFormatting('th', null);

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

        // Notification Bloc
        BlocProvider(
          create: (context) =>
              NotificationBloc(NotificationApiService())
                ..add(FetchNotifications()),
        ),

        // Navigation Cubit
        BlocProvider(create: (context) => NavigationCubit()),

        // Home Bloc - Move to global so all screens can access it
        BlocProvider(
          create: (context) => 
              HomeBloc(repository: context.read<RecipeRepository>()),
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
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
            locale: const Locale('th', 'TH'),
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
    ResponsiveHelper().init(context);
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          (previous is AuthUnauthenticated ||
              previous is AuthInitial ||
              previous is AuthLoading) &&
          current is AuthAuthenticated,
      listener: (context, state) {
        // Reset to Home tab (0) whenever a new authenticated session starts
        context.read<NavigationCubit>().setTab(0);
        // Refresh notifications upon authentication
        context.read<NotificationBloc>().add(FetchNotifications());
        // Load Home Recipes upon authentication
        if (state is AuthAuthenticated) {
          context.read<HomeBloc>().add(LoadHomeRecipes(isGuest: state.user.isGuest));
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is AuthInitial) {
            return const SplashScreen();
          }

          if (state is AuthAuthenticated) {
            return const MainNavigationScreen();
          }

          if (state is AuthGoogleRegistrationRequired) {
            return GoogleRegisterScreen(tempToken: state.tempToken);
          }

          if (state is AuthError) {
            final prefs = SharedPreferences.getInstance();
            return FutureBuilder<SharedPreferences>(
              future: prefs,
              builder: (context, snapshot) {
                final isCompleted =
                    snapshot.data?.getBool('onboarding_completed') ?? false;
                if (isCompleted) return const LoginScreen();
                return const OnboardingScreen();
              },
            );
          }

          if (state is AuthUnauthenticated) {
            final isCompleted = state.isOnboardingCompleted;
            if (isCompleted == true) {
              return const LoginScreen();
            }
            return const OnboardingScreen();
          }

          // Catch-all: show onboarding if not completed, otherwise login
          return const OnboardingScreen();
        },
      ),
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
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
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
                child: ClipOval(
                  child: Image.asset(
                    AppTheme.splashLogo,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
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
    final isGuest = context.watch<AuthCubit>().isGuest;

    // Filter screens and destinations based on authentication
    List<Widget> currentScreens = [const HomeScreen()];
    List<NavigationDestination> currentDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(
          Icons.restaurant_menu,
          color: const Color(0xFF8E54E2),
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
            color: const Color(0xFF8E54E2),
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
        selectedIcon: Icon(Icons.shopping_cart, color: const Color(0xFF8E54E2)),
        label: 'จ่ายตลาด',
      ),
    );

    currentScreens.add(const ProfileScreen());
    currentDestinations.add(
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: const Color(0xFF8E54E2)),
        label: 'โปรไฟล์',
      ),
    );

    final selectedIndex = context.watch<NavigationCubit>().state;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: currentScreens[selectedIndex],
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
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.read<NavigationCubit>().setTab(index);
            },
            backgroundColor: isDarkMode
                ? const Color(0xFF16213E)
                : Colors.white,
            indicatorColor: const Color(0xFF8E54E2).withOpacity(0.2),
            destinations: currentDestinations,
          ),
        ),
      ),
    );
  }
}
