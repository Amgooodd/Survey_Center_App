import 'package:flutter/material.dart';
import 'package:student_questionnaire/screens/AdminHome/admin_management.dart';
import 'package:student_questionnaire/screens/AdminHome/anal.dart';
import 'screens/AppStart/Splash_screen.dart';
import 'screens/AppStart/Welcome_screen.dart';
import 'screens/AdminHome/admin_home.dart';
import 'screens/AdminHome/survey_create.dart';
import 'screens/groups/groups_main.dart';
import 'screens/groups/groups_details.dart';
import 'screens/Auth/login_page.dart';
import 'screens/AdminHome/surveys_analytics.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => SplashScreen(),
    '/first': (context) => FirstImageScreen(),
    '/firsrforadminn': (context) => FirstForAdmin(),
    '/createsurvv': (context) => CreateSurvey(),
    '/groupp': (context) => Group(),
    '/complog': (context) => CombinedLogin(),
    '/elanall': (context) => DataPage(),
    '/admin-management': (context) => AdminManagementScreen(
          currentAdminId: '',
        ),
    '/surveysanal': (context) => const SurveyAnalysisPage(
          surveyId: '',
        ),
    '/groupDetails': (context) => GroupDetailsScreen(
          groupId: ModalRoute.of(context)!.settings.arguments as String,
        )
  };
}
