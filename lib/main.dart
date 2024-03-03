// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  RTCPeerConnection? _peerConnection1;
  RTCPeerConnection? _peerConnection2;
  RTCDataChannel? _dataChannel1;
  RTCDataChannel? _dataChannel2;
  RTCIceCandidate? _iceCandidate1;
  RTCIceCandidate? _iceCandidate2;
  RTCSessionDescription? _offer;
  RTCSessionDescription? _answer;

  String? message1;
  String? message2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: message1 != null
                      ? Center(child: Text(message1!))
                      : const SizedBox(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _dataChannel1?.send(
                      RTCDataChannelMessage(
                        'Hello, Peer 2! ${Random().nextInt(1000000)}',
                      ),
                    );
                  },
                  child: const Text('Send Message From Peer 1'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _createPeerConnection1();
                  },
                  child: const Text('Connect Peer 1'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: message2 != null
                      ? Center(child: Text(message2!))
                      : const SizedBox(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _dataChannel2?.send(
                      RTCDataChannelMessage(
                        'Hello, Peer 1! ${Random().nextInt(1000000)}',
                      ),
                    );
                  },
                  child: const Text('Send Message From Peer 2'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _createPeerConnection2();
                  },
                  child: const Text('Connect Peer 2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPeerConnection1() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    _peerConnection1 = await createPeerConnection(configuration);

    _peerConnection1?.onIceCandidate = (candidate) {
      _iceCandidate1 = candidate;
      _setIceCandidates();
    };

    _dataChannel1 = await _peerConnection1?.createDataChannel(
      'data-channel',
      RTCDataChannelInit()..id = 1,
    );
    _setDataChannelListener();

    _offer = await _peerConnection1!.createOffer();
    await _setRemoteAndLocalDescriprtion();
  }

  Future<void> _createPeerConnection2() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    _peerConnection2 = await createPeerConnection(configuration);

    _peerConnection2?.onIceCandidate = (candidate) {
      _iceCandidate2 = candidate;
      _setIceCandidates();
    };

    _peerConnection2?.onDataChannel = (channel) {
      _dataChannel2 = channel;
      _setDataChannelListener();
    };

    await _setRemoteAndLocalDescriprtion();
    _answer = await _peerConnection2!.createAnswer();
    await _setRemoteAndLocalDescriprtion();
  }

  Future<void> _setIceCandidates() async {
    if (_iceCandidate1 != null) {
      print('ICE Candidate 1: ${_iceCandidate1!.candidate}');
      await _peerConnection2?.addCandidate(_iceCandidate1!);
    }

    if (_iceCandidate2 != null) {
      print('ICE Candidate 2: ${_iceCandidate2!.candidate}');
      await _peerConnection1?.addCandidate(_iceCandidate2!);
    }
  }

  Future<void> _setRemoteAndLocalDescriprtion() async {
    if (_offer != null) {
      print('Offer SDP: ${_offer!.sdp}');
      if (_peerConnection1 != null) {
        await _peerConnection1?.setLocalDescription(_offer!);
      }

      if (_peerConnection2 != null) {
        await _peerConnection2?.setRemoteDescription(_offer!);
      }
    }

    if (_answer != null) {
      print('Answer SDP: ${_answer!.sdp}');
      if (_peerConnection1 != null) {
        await _peerConnection1?.setRemoteDescription(_answer!);
      }
      if (_peerConnection2 != null) {
        await _peerConnection2?.setLocalDescription(_answer!);
      }
    }
  }

  Future<void> _setDataChannelListener() async {
    if (_dataChannel1 != null) {
      _dataChannel1?.onMessage = (message) {
        message2 = message.text;
        setState(() {});
      };
    }

    if (_dataChannel2 != null) {
      _dataChannel2?.onMessage = (message) {
        message1 = message.text;
        setState(() {});
      };
    }
  }
}
