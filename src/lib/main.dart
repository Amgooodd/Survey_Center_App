import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:student_questionnaire/Features/firebase_options.dart';
import 'app_routes.dart';
import 'providers/user_provider.dart';
import 'connectivity_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  OverlayEntry? _overlayEntry;
  bool _isDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _connectivityService.connectionStatus.listen((connected) {
      if (!connected) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _showNoInternetDialog());
      } else {
        _dismissDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    if (_isDialogVisible) return;

    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          Center(
            child: AlertDialog(
              title: const Text('No Internet Connection'),
              content:
                  const Text('Please check your connection and try again.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    final hasConnection =
                        await _connectivityService.checkConnection();
                    if (hasConnection) _dismissDialog();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    _isDialogVisible = true;
  }

  void _dismissDialog() {
    if (_isDialogVisible && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isDialogVisible = false;
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    _dismissDialog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Survey App',
        initialRoute: '/',
        routes: AppRoutes.routes,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
