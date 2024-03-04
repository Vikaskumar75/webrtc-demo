// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CommunicationService {
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCPeerConnection? peerConnection;
  late final DocumentReference roomRef;
  late final CollectionReference dialerRef;
  late final CollectionReference recieverRef;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      },
    ],
  };

  void initialize() {
    localRenderer.initialize();
    remoteRenderer.initialize();
    roomRef = FirebaseFirestore.instance
        .collection('rooms')
        .doc('V2JcFD6cACuWreI01pNy');
    dialerRef = roomRef.collection('dialer');
    recieverRef = roomRef.collection('reciever');
  }

  Future<void> startVideoStream() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    localRenderer.srcObject = localStream;
  }

  // Step-1: Create Peer Connection
  // Step-1 a: add local stream to peerConnection
  // Step-1 b: Tell peer connection what kind of data you are transferring

  // Step-2: Listen for ice candidates
  // Step-2 a: Send ice candidates to firebase. So, that other peer can add it to their peerConnection

  // Step-3: Create offer
  // Step-3 a: Set local description
  // Step-3 b: Send offer to firebase

  // Step-4: Listen for answer
  // Step-4 a: Set remote description

  // Step-5: Listen for ice candidates
  // Step-5 a: Add ice candidates to peerConnection

  Future<void> call() async {
    peerConnection = await createPeerConnection(configuration);
    if (peerConnection == null) return;

    registerPeerConnectionListeners();

    if (localStream != null) {
      localStream!.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });
    }

    peerConnection!.onTrack = (event) {
      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    peerConnection!.onIceCandidate = (candidate) {
      recieverRef.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    await roomRef.set({'offer': offer.toMap()});
    print('New room created with SDK offer. Room ID: ${roomRef.id}');

    roomRef.snapshots().listen((snapshot) async {
      if (snapshot.data() == null) return;
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['answer'] != null) {
        RTCSessionDescription answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection!.setRemoteDescription(answer);
      }
    });

    dialerRef.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  Future<void> accept(String roomId) async {
    peerConnection = await createPeerConnection(configuration);
    if (peerConnection == null) return;
    registerPeerConnectionListeners();

    if (localStream != null) {
      localStream!.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });
    }

    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    peerConnection!.onIceCandidate = (candidate) {
      dialerRef.add(candidate.toMap());
    };

    final doc =
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();

    if (doc.data() == null) return;
    final roomData = doc.data() as Map<String, dynamic>;
    if (roomData['offer'] != null) {
      RTCSessionDescription offer = RTCSessionDescription(
        roomData['offer']['sdp'],
        roomData['offer']['type'],
      );
      await peerConnection!.setRemoteDescription(offer);
    }

    final answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    await roomRef.update({'answer': answer.toMap()});

    recieverRef.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
      remoteStream = stream;
    };
  }

  Future<void> hangUp() async {
    await localStream?.dispose();
    await remoteStream?.dispose();
  }

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
