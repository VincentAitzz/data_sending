import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.X");
  WebSocketChannel? _channel;
  bool _isConnected = false;

  void _toggleConnection() {
    if (_isConnected) {
      _channel?.sink.close();
      setState(() => _isConnected = false);
    } else {
      final ip = _ipController.text.trim();
      _channel = WebSocketChannel.connect(Uri.parse('ws://$ip:8080/ws'));
      setState(() => _isConnected = true);
    }
  }

  void _sendMockData() {
    if (_channel == null || !_isConnected) return;

    final payload = {
      "timestamp": DateTime.now().toIso8601String(),
      "device_id": "test_device_01",
      "sensors": {
        "accelerometer": [0.1, -0.5, 9.8],
        "gyroscope": [0.0, 0.0, 0.0]
      },
      "frame": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" 
    };

    _channel!.sink.add(jsonEncode(payload));
    
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paquete mock enviado 🚀'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexión Base'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'IP del Servidor Python',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                ),
                prefixIcon: Icon(Icons.wifi, color: _isConnected ? Colors.green : Colors.grey),
              ),
              enabled: !_isConnected,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.redAccent : const Color(0xFF1E1E1E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: _isConnected ? Colors.red : const Color(0xFFFFD700)),
                    ),
                    onPressed: _toggleConnection,
                    child: Text(
                      _isConnected ? 'Desconectar' : 'Conectar Socket',
                      style: TextStyle(color: _isConnected ? Colors.white : const Color(0xFFFFD700)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                ),
                onPressed: _isConnected ? _sendMockData : null,
                icon: const Icon(Icons.send),
                label: const Text('ENVIAR PAYLOAD FALSO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}