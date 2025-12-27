import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/call_provider.dart';
import 'services/audio_service.dart';
import 'services/gradio_tts_service.dart';
import 'services/todo_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final todoService = TodoService();
  await todoService.loadTodos();

  // Use 10.0.2.2 for Android emulator (host machine loopback)
  // Use localhost for physical devices on same network or other platforms
  String ttsHost = 'http://localhost:7860';
  if (!kIsWeb && Platform.isAndroid) {
    ttsHost = 'http://10.0.2.2:7860';
  }

  final ttsService = GradioTtsService(
    baseUrl: ttsHost,
  );

  final audioService = AudioService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CallProvider(
            todoService: todoService,
            ttsService: ttsService,
            audioService: audioService,
          ),
        ),
      ],
      child: const VoiceTodoApp(),
    ),
  );
}

class VoiceTodoApp extends StatelessWidget {
  const VoiceTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Todo Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade400,
          secondary: Colors.purple.shade400,
          surface: const Color(0xFF0f0f23),
        ),
        scaffoldBackgroundColor: const Color(0xFF0f0f23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f0f23),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
