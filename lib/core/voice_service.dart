import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VoiceService {
  final WebSocketChannel socket;

  RTCPeerConnection? _pc;
  MediaStream? _stream;

  VoiceService(this.socket);

  final _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  Future init() async {
    _stream = await navigator.mediaDevices.getUserMedia({'audio': true});

    _pc = await createPeerConnection(_config);

    for (var t in _stream!.getTracks()) {
      _pc!.addTrack(t, _stream!);
    }

    _pc!.onIceCandidate = (c) {
      socket.sink.add(jsonEncode({
        "type": "ice",
        "candidate": c.toMap()
      }));
    };
  }

  Future start() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    socket.sink.add(jsonEncode({
      "type": "offer",
      "sdp": offer.sdp
    }));
  }

  Future onOffer(String sdp) async {
    await _pc!.setRemoteDescription(
      RTCSessionDescription(sdp, "offer"),
    );

    final ans = await _pc!.createAnswer();
    await _pc!.setLocalDescription(ans);

    socket.sink.add(jsonEncode({
      "type": "answer",
      "sdp": ans.sdp
    }));
  }

  Future onAnswer(String sdp) async {
    await _pc!.setRemoteDescription(
      RTCSessionDescription(sdp, "answer"),
    );
  }

  Future onIce(Map c) async {
    await _pc!.addCandidate(
      RTCIceCandidate(
        c['candidate'],
        c['sdpMid'],
        c['sdpMLineIndex'],
      ),
    );
  }

  void mute(bool v) {
    for (var t in _stream!.getAudioTracks()) {
      t.enabled = !v;
    }
  }

  void dispose() {
    // _stream?.dispose();
    _pc?.close();
  }
}
