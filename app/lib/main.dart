import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/collection_provider.dart';
import 'providers/trade_provider.dart';
import 'screens/ar_scan_screen.dart';
import 'screens/collection_screen.dart';
import 'services/auth_service.dart';
import 'services/collection_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CritterCollectBootstrap());
}

/// Поднимает инфраструктуру (Hive, Firebase) до сборки дерева провайдеров.
///
/// Firebase требует нативных конфигов: `google-services.json` для Android и
/// `GoogleService-Info.plist` для iOS. В CI-сборке без них приложение должно
/// показать понятный экран-заглушку, а не падать с необработанным исключением.
class CritterCollectBootstrap extends StatefulWidget {
  const CritterCollectBootstrap({super.key});

  @override
  State<CritterCollectBootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<CritterCollectBootstrap> {
  late final CollectionRepository _repo = CollectionRepository();
  AuthProvider? _auth;
  AuthService? _authService;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _repo.init();
      await Firebase.initializeApp();
      final service = AuthService();
      final auth = AuthProvider(service)..listen();
      if (mounted) {
        setState(() {
          _authService = service;
          _auth = auth;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _BootstrapFailedApp(error: error);
    }
    final auth = _auth;
    final service = _authService;
    if (auth == null || service == null) {
      return const _SplashApp();
    }
    return CritterCollectApp(repo: _repo, auth: auth, authService: service);
  }
}

/// Корень приложения: провайдеры состояния и навигация по двум вкладкам.
class CritterCollectApp extends StatelessWidget {
  CritterCollectApp({
    super.key,
    required this.repo,
    required this.auth,
    required this.authService,
  }) : router = _buildRouter();

  final CollectionRepository repo;
  final AuthProvider auth;
  final AuthService authService;

  /// Хранится в поле, чтобы не пересоздаваться на каждом rebuild.
  final GoRouter router;

  static GoRouter _buildRouter() => GoRouter(
        initialLocation: '/scan',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => _HomeShell(shell: shell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/scan',
                  builder: (context, state) => const ArScanScreen(),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/collection',
                  builder: (context, state) => const CollectionScreen(),
                ),
              ]),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CollectionProvider>(
          create: (_) => CollectionProvider(repo),
        ),
        ChangeNotifierProvider<TradeProvider>(
          create: (_) => TradeProvider(authService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Critter Collect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}

/// Каркас с нижней навигацией; индекс вкладки хранится в URL.
class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Скан',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Коллекция',
          ),
        ],
      ),
    );
  }
}

class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// Экран на случай, если не удалось поднять Hive или Firebase.
class _BootstrapFailedApp extends StatelessWidget {
  const _BootstrapFailedApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Critter Collect')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Не удалось инициализировать приложение',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Проверьте наличие google-services.json (Android) и '
                'GoogleService-Info.plist (iOS), а также доступ к Hive.',
              ),
              const SizedBox(height: 16),
              SelectableText(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
