import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_demo/communication_service.dart';
import 'package:webrtc_demo/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter WebRTC Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CommunicationService _communicationService = CommunicationService();

  @override
  void initState() {
    _communicationService.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _communicationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                text: 'Start Camera',
                onPressed: _communicationService.startVideoStream,
              ),
              const SizedBox(width: 20),
              _buildButton(
                text: 'Call',
                onPressed: () {
                  _communicationService.call();
                },
              ),
              const SizedBox(width: 20),
              _buildButton(
                text: 'Accept',
                onPressed: () {
                  _communicationService.accept('V2JcFD6cACuWreI01pNy');
                },
              ),
              const SizedBox(width: 20),
              _buildButton(
                text: 'Hang Up',
                onPressed: _communicationService.hangUp,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: RTCVideoView(
                    _communicationService.localRenderer,
                    mirror: true,
                  ),
                ),
                Expanded(
                  child: RTCVideoView(_communicationService.remoteRenderer),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
