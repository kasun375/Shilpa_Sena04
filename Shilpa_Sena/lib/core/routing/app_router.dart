import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/courses/presentation/screens/recordings_screen.dart';
import '../../features/courses/presentation/screens/study_packs_screen.dart';
import '../../features/home/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/courses/presentation/screens/my_courses_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_courses_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_recordings_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_study_packs_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_students_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/user_list_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_promos_screen.dart';
import 'package:exim_graphics_lms/features/admin/presentation/screens/manage_announcements_screen.dart';
import 'package:exim_graphics_lms/features/info/presentation/screens/privacy_policy_screen.dart';
import 'package:exim_graphics_lms/features/info/presentation/screens/terms_conditions_screen.dart';
import 'package:exim_graphics_lms/features/info/presentation/screens/refund_policy_screen.dart';
import 'package:exim_graphics_lms/features/info/presentation/screens/contact_us_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        name: 'contact-us',
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-conditions',
        name: 'terms-conditions',
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: '/refund-policy',
        name: 'refund-policy',
        builder: (context, state) => const RefundPolicyScreen(),
      ),
      GoRoute(
        path: '/courses',
        name: 'courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/my-courses',
        name: 'my-courses',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      GoRoute(
        path: '/recordings',
        name: 'recordings',
        builder: (context, state) => const RecordingsScreen(),
      ),
      GoRoute(
        path: '/studypacks',
        name: 'studypacks',
        builder: (context, state) => const StudyPacksScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'manage-courses',
            name: 'manage-courses',
            builder: (context, state) => const ManageCoursesScreen(),
          ),
          GoRoute(
            path: 'manage-students',
            name: 'manage-students',
            builder: (context, state) => const ManageStudentsScreen(),
          ),
          GoRoute(
            path: 'manage-users',
            name: 'manage-users',
            builder: (context, state) => const UserListScreen(),
          ),
          GoRoute(
            path: 'manage-promos',
            name: 'manage-promos',
            builder: (context, state) => const ManagePromosScreen(),
          ),
          GoRoute(
            path: 'manage-recordings',
            name: 'manage-recordings',
            builder: (context, state) => const ManageRecordingsScreen(),
          ),
          GoRoute(
            path: 'manage-study-packs',
            name: 'manage-study-packs',
            builder: (context, state) => const ManageStudyPacksScreen(),
          ),
          GoRoute(
            path: 'manage-announcements',
            name: 'manage-announcements',
            builder: (context, state) => const ManageAnnouncementsScreen(),
          ),
        ],
      ),
    ],
  );
}
