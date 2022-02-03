/// 程序入口

import 'dart:async';

import 'package:bfban/provider/message_provider.dart';
import 'package:bfban/provider/package_provider.dart';
import 'package:bfban/provider/theme_provider.dart';
import 'package:bfban/provider/translation_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:sentry/sentry.dart';
import 'package:provider/provider.dart';
import 'package:bfban/provider/userinfo_provider.dart';
import 'package:jpush_flutter/jpush_flutter.dart';

import 'package:bfban/router/router.dart';
import 'package:bfban/constants/api.dart';
import 'package:bfban/utils/index.dart';

// 入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google ads 初始
  // MobileAds.instance.initialize();

  // 极光
  JPush().setup(
    appKey: Config.jiguan["appKey"],
    channel: Config.jiguan["channel"],
  );

  // 翻译
  var delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en_US',
    supportedLocales: ['en_US', 'zh', 'zh_Hans', 'zh_Hant'],
  );

  // 路由初始
  Routes.configureRoutes(FluroRouter());

  // 应用版本模式
  Config.env = Env.PROD;

  // 相机初始
  Camera.camera = await availableCameras();

  // 设置系统演示
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
  );
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  runZonedGuarded(
    () async {
      await Sentry.init(
        (options) {
          options.dsn = Config.apiHost["sentry"];
        },
      );

      runApp(LocalizedApp(delegate, const BfBanApp()));
    },
    (exception, stackTrace) async {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    },
  );
}

class BfBanApp extends StatefulWidget {
  const BfBanApp({Key? key}) : super(key: key);

  @override
  _BfBanAppState createState() => _BfBanAppState();
}

class _BfBanAppState extends State<BfBanApp> {
  @override
  Widget build(BuildContext context) {
    // 翻译
    // LocalizationProvider
    var localizationDelegate = LocalizedApp.of(context).delegate;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppInfoProvider()),
        ChangeNotifierProvider(create: (context) => UserInfoProvider()),
        ChangeNotifierProvider(create: (context) => MessageProvider()),
        ChangeNotifierProvider(create: (context) => PackageProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => TranslationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext? ThemeContext, data, Widget? child) {
          return LocalizationProvider(
            state: LocalizationProvider.of(context).state,
            child: MaterialApp(
              theme: data.currentThemeData,
              darkTheme: data.list!["default"]!.themeData!,
              initialRoute: '/splash',
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                localizationDelegate,
              ],
              builder: (BuildContext context, Widget? widget) {
                ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                  return CustomError(errorDetails: errorDetails);
                };

                return widget!;
              },
              supportedLocales: localizationDelegate.supportedLocales,
              locale: localizationDelegate.currentLocale,
              onGenerateRoute: Routes.router!.generator,
            ),
          );
        },
      ),
    );
  }
}

class CustomError extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;

  const CustomError({
    Key? key,
    required this.errorDetails,
  })  : assert(errorDetails != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        child: Text(
          errorDetails!.library.toString(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        padding: EdgeInsets.all(8.0),
      ),
      color: Colors.red,
      margin: EdgeInsets.zero,
    );
  }
}
