import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/accounts/screens/accounts_list_screen.dart';
import '../../features/accounts/screens/account_detail_screen.dart';
import '../../features/accounts/screens/account_form_screen.dart';
import '../../features/transactions/screens/transaction_form_screen.dart';
import '../../features/cash/screens/cash_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/cheques/screens/cheques_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Ana ekran - bottom nav shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsListScreen(),
          ),
          GoRoute(
            path: '/cash',
            builder: (context, state) => const CashScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Detay ekranları (shell dışı)
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => AccountDetailScreen(
          accountId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/accounts/new',
        builder: (context, state) => const AccountFormScreen(),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (context, state) => AccountFormScreen(
          accountId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => TransactionFormScreen(
          accountId: state.uri.queryParameters['accountId'],
          type: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/cheques',
        builder: (context, state) => const ChequesScreen(),
      ),
    ],
  );
});

