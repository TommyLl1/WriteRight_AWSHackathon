import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view/pages/export.dart';
import 'package:writeright/new/ui/view_model/exports.dart';
import 'package:writeright/new/data/services/exports.dart';
import 'package:writeright/new/data/api_service.dart';
import 'package:writeright/new/data/models/game.dart';
import 'transitions.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/get-photo',
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) => GetPhotoViewModel(
              context.read<PermissionService>(),
              context.read<WrongCharacterService>(),
            ),
            child: GetPhotoPage(),
          ),
        ),
      ),
      GoRoute(
        path: "/login",
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) => LoginViewModel(
              context.read<AuthService>(),
              context.read<CommonImageCache>(),
            ),
            child: LoginPage(),
          ),
        ),
      ),
      GoRoute(
        path: "/wrong-chars",
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) => DictionaryViewModel(
              context.read<WrongCharacterService>(),
              context.read<SettingService>(),
            ),
            child: DictionaryPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => FadeTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: '/exercise',
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) =>
                ExerciseViewModel(imageCache: context.read<CommonImageCache>()),
            child: ExercisePage(),
          ),
        ),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) {
          SubmitResponse? result;
          try {
            result = state.extra as SubmitResponse;
          } catch (e) {
            result = null;
          }
          return FadeTransitionPage(child: ResultPage(result: result));
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            FadeTransitionPage(child: SettingsPage()),
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) =>
                GameViewModel(gameService: context.read<GameService>()),
            child: GamePage(),
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) =>
                ProfileViewModel(apiService: context.read<ApiService>()),
            child: ProfilePage(),
          ),
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (context, state) => FadeTransitionPage(
          child: ChangeNotifierProvider(
            create: (context) => AccountViewModel(
              apiService: context.read<ApiService>(),
              authService: context.read<AuthService>(),
            ),
            child: AccountPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => FadeTransitionPage(child: AboutPage()),
      ),
    ],
  );
}
