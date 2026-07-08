import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/network_test_screen.dart';
import 'screens/camera_stream_screen.dart';

Future<void> main() async {
  // 1. Estrictamente necesario antes de llamar a plugins nativos como la cámara
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Obtenemos las cámaras disponibles al inicio de la app
  final cameras = await availableCameras();
  
  // 3. Pasamos las cámaras como dependencia
  runApp(TrazeursTestClient(cameras: cameras));
}

class TrazeursTestClient extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const TrazeursTestClient({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trazeurs Engine',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: MainMenuScreen(cameras: cameras),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MainMenuScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trazeurs Engine', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: const Color(0xFFFFD700),
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Color(0xFFFFD700)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NetworkTestScreen()),
                  );
                },
                icon: const Icon(Icons.wifi),
                label: const Text('1. Prueba de Red (Mock)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: const Color(0xFFFFD700),
                  minimumSize: const Size(double.infinity, 60),
                  side: const BorderSide(color: Color(0xFFFFD700)),
                ),
                onPressed: () {
                  // Ahora simplemente pasamos la variable ya resuelta
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraStreamScreen(cameras: cameras),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('2. Streaming de Cámara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}