import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/design_storage_service.dart';
import 'services/iap_service.dart';
import 'services/reward_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Core storage
  final storage = await StorageService.create();
  final prefs = await SharedPreferences.getInstance();

  // Design storage (My Designs)
  final designStorage = await DesignStorageService.create();

  // Reward service (daily unlock tracking)
  final rewardService = RewardService(prefs);
  await rewardService.resetIfNewDay();

  // Ads + IAP
  await AdsService.init();
  final adsService = AdsService(storage, rewardService);
  final iapService = IapService(storage);
  await iapService.init();

  runApp(DateWidgetApp(
    storage: storage,
    designStorage: designStorage,
    adsService: adsService,
    iapService: iapService,
    rewardService: rewardService,
  ));
}

class DateWidgetApp extends StatefulWidget {
  final StorageService storage;
  final DesignStorageService designStorage;
  final AdsService adsService;
  final IapService iapService;
  final RewardService rewardService;

  const DateWidgetApp({
    super.key,
    required this.storage,
    required this.designStorage,
    required this.adsService,
    required this.iapService,
    required this.rewardService,
  });

  @override
  State<DateWidgetApp> createState() => _DateWidgetAppState();
}

class _DateWidgetAppState extends State<DateWidgetApp>
    with WidgetsBindingObserver {
  final _deepLinkChannel = MethodChannel(
    'com.example.date_time_widget/deep_link',
  );

  /// Global key to access HomeScreen state for triggering editor open
  final _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkChannel.setMethodCallHandler(_handleDeepLink);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.iapService.dispose();
    widget.adsService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      widget.iapService.dispose();
      widget.adsService.dispose();
    }
  }

  Future<void> _handleDeepLink(MethodCall call) async {
    if (call.method == 'openEditor') {
      // Small delay to ensure HomeScreen is mounted
      await Future.delayed(const Duration(milliseconds: 500));
      _homeKey.currentState?.openEditorFromDeepLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Date & Time Widget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        key: _homeKey,
        storage: widget.storage,
        designStorage: widget.designStorage,
        adsService: widget.adsService,
        iapService: widget.iapService,
        rewardService: widget.rewardService,
      ),
    );
  }
}
