import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'story/story_controller.dart';
import 'ui/echo_experience.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const GalgameApp());
}

class GalgameApp extends StatelessWidget {
  const GalgameApp({super.key, this.audioEnabled = true});

  final bool audioEnabled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '零点协议',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B0C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD8A24A),
          secondary: Color(0xFF69A89D),
          surface: Color(0xFF13191A),
          error: Color(0xFFD9695F),
        ),
        fontFamilyFallback: const [
          'PingFang SC',
          'Microsoft YaHei',
          'Noto Sans CJK SC',
        ],
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w300,
            letterSpacing: 0,
            height: 1.05,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          bodyLarge: TextStyle(fontSize: 17, height: 1.75, letterSpacing: 0),
        ),
      ),
      home: FutureBuilder<StoryController>(
        future: StoryController.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ColoredBox(
              color: Color(0xFF080B0C),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return EchoExperience(
            controller: snapshot.data!,
            audioEnabled: audioEnabled,
          );
        },
      ),
    );
  }
}
