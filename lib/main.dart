import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/api_client.dart';
import 'core/config.dart';
import 'repositories/admin_repository.dart';
import 'repositories/api_client_repository.dart';
import 'repositories/api_hotel_repository.dart';
import 'repositories/api_lookup_repositories.dart';
import 'repositories/api_tour_repository.dart';
import 'repositories/auth_api.dart';
import 'repositories/booking_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/hotel_repository.dart';
import 'repositories/lookup_repositories.dart';
import 'repositories/tour_repository.dart';
import 'state/auth_notifier.dart';
import 'state/catalog_list_notifiers.dart';
import 'state/catalog_lookups.dart';
import 'state/hotel_list_notifier.dart';
import 'state/tour_list_notifier.dart';
import 'models/role.dart';
import 'widgets/connectivity_restorer.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  final prefs = await SharedPreferences.getInstance();
  late final AuthNotifier auth;
  final dio = buildDio(tokenProvider: () => auth.accessToken);
  auth = AuthNotifier(prefs, AuthApi(dio));
  attachRefreshInterceptor(dio, auth);
  await auth.restore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<Dio>.value(value: dio),
        Provider<BookingRepository>(create: (_) => BookingRepository(dio)),
        Provider<AdminRepository>(create: (_) => AdminRepository(dio)),
        ProxyProvider<Dio, TourRepository>(
          update: (_, client, previous) =>
              previous ?? ApiTourRepository(client),
        ),
        ProxyProvider<Dio, HotelRepository>(
          update: (_, client, previous) =>
              previous ?? ApiHotelRepository(client),
        ),
        ProxyProvider<Dio, DestinationRepository>(
          update: (_, client, previous) =>
              previous ?? ApiDestinationRepository(client),
        ),
        ProxyProvider<Dio, CategoryRepository>(
          update: (_, client, previous) =>
              previous ?? ApiCategoryRepository(client),
        ),
        ProxyProvider<Dio, ClientRepository>(
          update: (_, client, previous) =>
              previous ?? ApiClientRepository(client),
        ),
        ChangeNotifierProxyProvider3<
          DestinationRepository,
          HotelRepository,
          CategoryRepository,
          CatalogLookups
        >(
          create: (context) => CatalogLookups(
            destinations: context.read<DestinationRepository>(),
            hotels: context.read<HotelRepository>(),
            categories: context.read<CategoryRepository>(),
          ),
          update: (_, destinations, hotels, categories, previous) =>
              previous ??
              CatalogLookups(
                destinations: destinations,
                hotels: hotels,
                categories: categories,
              ),
        ),
        ChangeNotifierProxyProvider<TourRepository, TourListNotifier>(
          create: (context) => TourListNotifier(context.read<TourRepository>()),
          update: (_, repo, previous) => previous ?? TourListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<HotelRepository, HotelListNotifier>(
          create: (context) =>
              HotelListNotifier(context.read<HotelRepository>()),
          update: (_, repo, previous) => previous ?? HotelListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<
          DestinationRepository,
          DestinationListNotifier
        >(
          create: (context) =>
              DestinationListNotifier(context.read<DestinationRepository>()),
          update: (_, repo, previous) =>
              previous ?? DestinationListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<CategoryRepository, CategoryListNotifier>(
          create: (context) =>
              CategoryListNotifier(context.read<CategoryRepository>()),
          update: (_, repo, previous) => previous ?? CategoryListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<ClientRepository, ClientListNotifier>(
          create: (context) =>
              ClientListNotifier(context.read<ClientRepository>()),
          update: (_, repo, previous) => previous ?? ClientListNotifier(repo),
        ),
      ],
      child: FlyYApp(auth: auth),
    ),
  );
}

class FlyYApp extends StatefulWidget {
  final AuthNotifier auth;

  const FlyYApp({super.key, required this.auth});

  @override
  State<FlyYApp> createState() => _FlyYAppState();
}

class _FlyYAppState extends State<FlyYApp> {
  late final GoRouter _router = createRouter(widget.auth);
  bool _warned = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fly-Y — каталог туров',
      debugShowCheckedModeBanner: false,
      theme: _seaTheme,
      routerConfig: _router,
      builder: (context, child) {
        return ConnectivityRestorer(
          onBackOnline: () {
            if (!context.mounted) return;
            final auth = context.read<AuthNotifier>();
            if (!auth.isAuthenticated) return;
            context.read<TourListNotifier>().load();
            if (auth.can(AppOp.manageCatalog) || auth.can(AppOp.hardDelete)) {
              context.read<HotelListNotifier>().load();
              context.read<DestinationListNotifier>().load();
              context.read<CategoryListNotifier>().load();
            }
            if (auth.can(AppOp.manageClients)) {
              context.read<ClientListNotifier>().load();
            }
          },
          child: InactivityWatcher(
            onActivity: () {
              _warned = false;
              final auth = context.read<AuthNotifier>();
              if (!auth.isAuthenticated) return;
              auth.markActivity();
              final started = auth.sessionStartedAt;
              if (started != null &&
                  DateTime.now().difference(started) >= maxSessionDuration) {
                auth.logout();
                _sessionMessage(
                  context,
                  'Сессия истекла по общему лимиту времени.',
                );
              }
            },
            onWarning: () {
              final auth = context.read<AuthNotifier>();
              if (!auth.isAuthenticated || _warned || !context.mounted) return;
              _warned = true;
              showDialog<void>(
                context: context,
                builder: (ctx) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AlertDialog(
                      alignment: Alignment.center,
                      title: const Text('Сессия скоро завершится'),
                      content: const Text(
                        'Не было действий 2,5 минуты. Через 30 секунд будет выход.',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Продолжить'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onTimeout: () {
              final auth = context.read<AuthNotifier>();
              if (!auth.isAuthenticated) return;
              auth.logout();
              _sessionMessage(context, 'Выход из‑за неактивности.');
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  void _sessionMessage(BuildContext context, String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          alignment: Alignment.center,
          title: const Text('Сессия завершена'),
          content: Text(text),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    });
  }
}

const _seaFoam = Color(0xFFEAF6F7);
const _seaMist = Color(0xFFC5E8EC);
const _seaWave = Color(0xFF4AA8B0);
const _seaInk = Color(0xFF1A3F44);

final ThemeData _seaTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: _seaWave,
    onPrimary: Colors.white,
    primaryContainer: _seaMist,
    onPrimaryContainer: _seaInk,
    secondary: Color(0xFF5E8E96),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD5EBEE),
    onSecondaryContainer: _seaInk,
    surface: Color(0xFFF5FBFC),
    onSurface: Color(0xFF1D3336),
    onSurfaceVariant: Color(0xFF4A6468),
    surfaceContainerHighest: Color(0xFFDCEEF0),
    outline: Color(0xFF8AAEB3),
    error: Color(0xFFB54A4A),
  ),
  scaffoldBackgroundColor: _seaFoam,
  appBarTheme: const AppBarTheme(
    backgroundColor: _seaMist,
    foregroundColor: _seaInk,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Color(0xFFD8EEF1),
    indicatorColor: _seaMist,
    selectedIconTheme: IconThemeData(color: _seaInk),
    selectedLabelTextStyle: TextStyle(color: _seaInk),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xFFD8EEF1),
    indicatorColor: _seaMist,
  ),
  dataTableTheme: const DataTableThemeData(
    headingRowColor: WidgetStatePropertyAll(Color(0xFFD8EEF1)),
  ),
);
