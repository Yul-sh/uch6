import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/catalog_query.dart';
import 'models/hotel_query.dart';
import 'models/role.dart';
import 'models/tour_query.dart';
import 'repositories/hotel_repository.dart';
import 'repositories/tour_repository.dart';
import 'screens/catalog_detail_screens.dart';
import 'screens/catalog_list_screens.dart';
import 'screens/client_form_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/hotel_detail_screen.dart';
import 'screens/hotel_form_screen.dart';
import 'screens/hotel_list_screen.dart';
import 'screens/issues_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lookup_form_screens.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/register_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/tour_detail_screen.dart';
import 'screens/tour_form_screen.dart';
import 'screens/tour_list_screen.dart';
import 'screens/users_screen.dart';
import 'state/auth_notifier.dart';
import 'state/hotel_detail_notifier.dart';
import 'state/tour_detail_notifier.dart';

String _id(GoRouterState state) => state.pathParameters['id'] ?? '';

String? _allow(AuthNotifier auth, AppOp op) =>
    auth.can(op) ? null : '/forbidden';

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/tours',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';
      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register')) {
          return from;
        }
        return '/tours';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/tours',
            builder: (context, state) =>
                TourListScreen(query: TourQuery.fromUri(state.uri)),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => const TourFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => TourFormScreen(id: _id(s)),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  return ChangeNotifierProvider(
                    create: (context) => TourDetailNotifier(
                      context.read<TourRepository>(),
                      _id(state),
                    )..load(),
                    child: const TourDetailScreen(),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/hotels',
            redirect: (c, s) =>
                auth.can(AppOp.manageCatalog) || auth.can(AppOp.hardDelete)
                ? null
                : '/forbidden',
            builder: (context, state) =>
                HotelListScreen(query: HotelQuery.fromUri(state.uri)),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => const HotelFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => HotelFormScreen(id: _id(s)),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  return ChangeNotifierProvider(
                    create: (context) => HotelDetailNotifier(
                      context.read<HotelRepository>(),
                      _id(state),
                    )..load(),
                    child: const HotelDetailScreen(),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/destinations',
            redirect: (c, s) =>
                auth.can(AppOp.manageCatalog) || auth.can(AppOp.hardDelete)
                ? null
                : '/forbidden',
            builder: (c, s) =>
                DestinationListScreen(query: CatalogQuery.fromUri(s.uri)),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => const DestinationFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => DestinationFormScreen(id: _id(s)),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => DestinationDetailScreen(id: _id(s)),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            redirect: (c, s) =>
                auth.can(AppOp.manageCatalog) || auth.can(AppOp.hardDelete)
                ? null
                : '/forbidden',
            builder: (c, s) =>
                CategoryListScreen(query: CatalogQuery.fromUri(s.uri)),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                redirect: (c, s) => _allow(auth, AppOp.manageCatalog),
                builder: (c, s) => CategoryFormScreen(id: _id(s)),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => CategoryDetailScreen(id: _id(s)),
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            redirect: (c, s) => _allow(auth, AppOp.manageClients),
            builder: (c, s) => ClientListScreen(
              query: CatalogQuery.fromUri(s.uri, defaultSort: 'lastName'),
            ),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const ClientFormScreen()),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => ClientFormScreen(id: _id(s)),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => ClientDetailScreen(id: _id(s)),
              ),
            ],
          ),
          GoRoute(
            path: '/my-bookings',
            redirect: (c, s) => _allow(auth, AppOp.viewOwnBookings),
            builder: (c, s) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: '/issues',
            redirect: (c, s) => _allow(auth, AppOp.closeBooking),
            builder: (c, s) => const IssuesScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (c, s) => _allow(auth, AppOp.manageUsers),
            builder: (c, s) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (c, s) => _allow(auth, AppOp.viewStats),
            builder: (c, s) => const StatsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Страница не найдена')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/tours'),
          child: const Text('К каталогу'),
        ),
      ),
    ),
  );
}
