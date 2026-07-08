import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CameraStreamScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraStreamScreen({super.key, required this.cameras});

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  Timer? _frameTimer;
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  List<double> _accelerometerValues = [0.0, 0.0, 0.0];
  List<double> _gyroscopeValues = [0.0, 0.0, 0.0];
  
  // Novedad: Almacenaremos las detecciones de YOLO aquí
  List<dynamic> _detections = [];

  final TextEditingController _ipController = TextEditingController(text: "192.168.1.X");
  bool _isConnected = false;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    
    _cameraController = CameraController(
      widget.cameras.first, 
      ResolutionPreset.low, 
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  void _toggleConnection() {
    if (_isConnected) {
      _stopStreaming();
      _channel?.sink.close();
      setState(() {
        _isConnected = false;
        _detections = []; // Limpiamos la pantalla al desconectar
      });
    } else {
      final ip = _ipController.text.trim();
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:8080/ws'));
      
      // Novedad: Escuchamos activamente lo que el servidor nos responde
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'ai_insight') {
            setState(() {
              _detections = data['detections'];
            });
          }
        },
        onError: (error) => debugPrint("Error de red: $error"),
        onDone: () {
          _stopStreaming();
          if (mounted) setState(() => _isConnected = false);
        },
      );
      
      setState(() => _isConnected = true);
    }
  }

  void _toggleStreaming() {
    if (_isStreaming) {
      _stopStreaming();
    } else {
      _startStreaming();
    }
  }

  void _startStreaming() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    setState(() => _isStreaming = true);

    _accelSubscription = accelerometerEventStream().listen((event) {
      _accelerometerValues = [event.x, event.y, event.z];
    });
    
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      _gyroscopeValues = [event.x, event.y, event.z];
    });
    
    _frameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!_isConnected || _channel == null) {
        _stopStreaming();
        return;
      }

      try {
        final XFile file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        final payload = {
          "timestamp": DateTime.now().toIso8601String(),
          "device_id": "camera_device_01",
          "sensors": {
            "accelerometer": _accelerometerValues,
            "gyroscope": _gyroscopeValues
          },
          "frame": base64Image
        };

        _channel!.sink.add(jsonEncode(payload));
      } catch (e) {
        debugPrint("Error capturando frame: $e");
      }
    });
  }

  void _stopStreaming() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isStreaming = false;
        _detections = []; // Limpiamos cajas al detener
      });
    }
  }

  @override
  void dispose() {
    _stopStreaming();
    _channel?.sink.close();
    _cameraController?.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visión AR')),
      body: Column(
        children: [
          // Novedad: El Stack superpone el lienzo transparente sobre la cámara
          Expanded(
            child: Container(
              color: const Color(0xFF121212),
              width: double.infinity,
              child: _cameraController != null && _cameraController!.value.isInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        CustomPaint(
                          painter: VisionOverlayPainter(_detections),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
            ),
          ),
          
          // Panel de Control inferior (Sin cambios)
          Container(
            padding: const EdgeInsets.all(24.0),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'IP del Servidor Python',
                    prefixIcon: Icon(Icons.wifi, color: _isConnected ? Colors.green : Colors.grey),
                  ),
                  enabled: !_isConnected,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected ? Colors.redAccent : const Color(0xFF121212),
                          side: BorderSide(color: _isConnected ? Colors.red : const Color(0xFFFFD700)),
                        ),
                        onPressed: _toggleConnection,
                        child: Text(_isConnected ? 'Desconectar' : 'Conectar', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStreaming ? Colors.red : const Color(0xFFFFD700),
                          foregroundColor: _isStreaming ? Colors.white : Colors.black,
                        ),
                        onPressed: _isConnected ? _toggleStreaming : null,
                        icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                        label: Text(_isStreaming ? 'Transmisión' : 'Transmisión'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PINTOR PERSONALIZADO AR (CustomPainter)
// ============================================================================
class VisionOverlayPainter extends CustomPainter {
  final List<dynamic> detections;

  VisionOverlayPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    // Configuración estética del trazo poligonal dorado
    final paintPolygon = Paint()
      ..color = const Color(0xFFFFD700) // Dorado Trazeurs
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round // Trazo más suave
      ..strokeJoin = StrokeJoin.round;

    final paintTextBg = Paint()
      ..color = const Color(0xFF1E1E1E).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var det in detections) {
      // Novedad: Ahora recibimos un polígono, no una caja cuadrada
      // polygon = Lista de Lista de <double> [[x,y], [x,y], ...] (Normalizados 0..1)
      final List<dynamic> polygonPoints = det['polygon']; 
      final label = det['label'];
      final conf = det['confidence'];

      if (polygonPoints.isEmpty) continue;

      // --- CONSTRUCCIÓN DEL POLÍGONO IRREGULAR (drawPath) ---
      final path = Path();
      bool isFirstPoint = true;

      // Variables para ubicar el texto en la parte superior del polígono
      double minY = size.height;
      double minX = size.width;

      for (var point in polygonPoints) {
        // --- Desnormalización Matemática Critica ---
        // Multiplicamos la coordenada (0..1) por el tamaño real de la pantalla
        double denormX = point[0] * size.width;
        double denormY = point[1] * size.height;

        if (isFirstPoint) {
          path.moveTo(denormX, denormY);
          isFirstPoint = false;
        } else {
          path.lineTo(denormX, denormY);
        }

        // Actualizamos los bordes para colocar el texto luego
        if (denormY < minY) minY = denormY;
        if (denormX < minX) minX = denormX;
      }
      path.close(); // Cerramos el polígono geométricamente

      // Dibujamos el contorno poligonal preciso sobre el objeto
      canvas.drawPath(path, paintPolygon);

      // --- DIBUJO DEL TEXTO (Etiqueta Minimalista monospaced) ---
      final textSpan = TextSpan(
        text: ' $label ${(conf * 100).toInt()}% ',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace'
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Ubicación del texto (justo arriba del punto más alto del polígono)
      double textX = minX;
      double textY = minY - textPainter.height;
      
      // Si el objeto está muy arriba, mostramos el texto dentro del contorno
      if (textY < 0) textY = minY;

      // Fondo oscuro para legibilidad del texto
      final textBgRect = Rect.fromLTWH(
        textX, 
        textY, 
        textPainter.width, 
        textPainter.height
      );
      canvas.drawRect(textBgRect, paintTextBg);

      // Pintamos el texto
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant VisionOverlayPainter oldDelegate) {
    return true; // Repintar siempre que lleguen nuevos datos
  }
}