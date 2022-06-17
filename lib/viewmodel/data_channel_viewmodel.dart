import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cheap_share/config/config.dart';
import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/base_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utils/download_util.dart'
    if (dart.library.js) '../utils/download_util_web.dart';

class DataChannelViewModel extends BaseViewModel {
  late io.Socket _socket;
  RTCPeerConnection? _peerConnection;
  String? _otherUserId;
  RTCDataChannelInit? _dataChannelDict;
  RTCDataChannel? _dataChannel;
  PlatformFile? _file;
  List<int> _receivedData = [];

  String? get otherUserId => _otherUserId;

  set otherUserId(String? id) {
    _otherUserId = id;
    notifyListeners();
  }

  String? _fileName;

  String? get fileName => _fileName;

  set fileName(String? name) {
    _fileName = name;
    notifyListeners();
  }

  final configuration = <String, dynamic>{
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final _configuration = <String, dynamic>{
    'iceServers': [
      {
        'urls': "stun:stun.stunprotocol.org",
      },
      {
        'urls': 'turn:numb.viagenie.ca',
        'credential': 'muazkh',
        'username': 'webrtc@live.com'
      },
    ]
  };

  final loopbackConstraints = <String, dynamic>{
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final offerSdpConstraints = <String, dynamic>{
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  void _onICECandidate(RTCIceCandidate candidate) async {
    if (candidate.candidate == null) return;

    final payload = {
      'target': _otherUserId,
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    };
    _socket.emit('ice-candidate', payload);
  }

  void _onRenegotiationNeeded(String socketId) async {
    debugPrint('Renegotitation Needed');
    try {
      final offer = await _peerConnection!.createOffer(offerSdpConstraints);
      await _peerConnection!.setLocalDescription(offer);
      final payload = {
        'target': socketId,
        'caller': _socket.id,
        'sdp': offer.sdp,
        'type': offer.type,
      };
      _socket.emit("offer", payload);
    } catch (err) {
      debugPrint("Error handling negotiation needed event ${err.toString()}");
    }
  }

  void _handleNewICECandidateData(Map<String, dynamic> iceCandidate) async {
    try {
      _peerConnection?.addCandidate(
        RTCIceCandidate(
          iceCandidate['candidate'],
          iceCandidate['sdpMid'],
          iceCandidate['sdpMLineIndex'],
        ),
      );
    } catch (err) {
      debugPrint('Error while add new ice candidate: $err');
    }
  }

  void dataChannelInit() {
    _dataChannelDict = RTCDataChannelInit();
    _dataChannelDict!.id = 1;
    _dataChannelDict!.ordered = true;
    _dataChannelDict!.maxRetransmitTime = -1;
    _dataChannelDict!.maxRetransmits = -1;
    _dataChannelDict!.protocol = 'sctp';
    _dataChannelDict!.negotiated = false;
  }

  void callUser() async {
    _peerConnection = await createPeer();
    _onRenegotiationNeeded(otherUserId ?? '');
    dataChannelInit();
    _dataChannel = await _peerConnection!
        .createDataChannel('dataChannel', _dataChannelDict!);

    _peerConnection!.onDataChannel = _onDataChannel;
  }

  void _onSignalingState(RTCSignalingState state) {
    debugPrint('Current state: ${state.name}');
  }

  Future<RTCPeerConnection> createPeer() async {
    final peer = await createPeerConnection(
      _configuration,
      loopbackConstraints,
    );
    peer.onIceCandidate = _onICECandidate;
    peer.onSignalingState = _onSignalingState;
    peer.onRenegotiationNeeded =
        () => _onRenegotiationNeeded(_otherUserId ?? '');

    return peer;
  }

  void _handleOffer(data) async {
    debugPrint('Handle offer, type: ${data['type']}');

    _peerConnection = await createPeer();
    dataChannelInit();
    _dataChannel = await _peerConnection!
        .createDataChannel('dataChannel', _dataChannelDict!);
    _peerConnection!.onDataChannel = _onDataChannel;

    try {
      final desc = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(desc);
      final answer = await _peerConnection!.createAnswer(offerSdpConstraints);
      await _peerConnection!.setLocalDescription(answer);
      final payload = {
        'target': _otherUserId,
        'caller': _socket.id,
        'sdp': answer.sdp,
        'type': answer.type,
      };

      _socket.emit('answer', payload);
    } catch (err) {
      debugPrint('Error occured while handling offer ${err.toString()}');
    }
  }

  void _handleAnswer(data) async {
    debugPrint('Handeling Answer type: ${data['type']}');

    final desc = RTCSessionDescription(data['sdp'], data['type']);
    try {
      await _peerConnection!.setRemoteDescription(desc);
    } catch (err) {
      debugPrint('Error occured while handeling answer ${err.toString()}');
    }
  }

  /// Send some sample messages and handle incoming messages.
  void _onDataChannel(RTCDataChannel dataChannel) {
    dataChannel.messageStream.listen((message) async {
      if (message.type == MessageType.text) {
        debugPrint(message.text);
        var response = {};
        try {
          response = json.decode(message.text);
        } catch (err) {
          debugPrint('Error occured while parsing, ${err.toString()}');
          return;
        }
        if (response['done']) {
          debugPrint('Received Data length: ${_receivedData.length}');
          await DownloadUtil.download(
            bytes: _receivedData,
            name: response['fileName'],
          );
          _receivedData = [];
          debugPrint('File received');
        } else {
          _receivedData = [];
        }
      } else {
        _receivedData.addAll(message.binary.toList());
      }
    });
  }

  void resetState() async {
    await FilePicker.platform.clearTemporaryFiles();
    fileName = '';
  }

  void pickFile() async {
    final file = await FilePicker.platform.pickFiles(
      withReadStream: true,
    );
    _file = file?.files.first;
    fileName = _file?.name;
  }

  void sendFile() {
    final fileStream = _file?.readStream;
    debugPrint('fileStream: ${fileStream != null}');
    if (fileStream == null) return;

    fileStream.listen(
      (data) {
        debugPrint('data send: ${data.length}');
        int initialIdx = 0, finalIdx;
        while (initialIdx < data.length) {
          finalIdx = min(initialIdx + 1200, data.length);

          // Converting the data to chunks
          final chunk = data.getRange(initialIdx, finalIdx).toList();
          _dataChannel?.send(
            RTCDataChannelMessage.fromBinary(
              Uint8List.fromList(chunk),
            ),
          );

          initialIdx = finalIdx;
        }
      },
      onDone: () {
        final res = {
          'done': true,
          'fileName': _file?.name,
        };
        debugPrint('Sent Successfully');
        _dataChannel?.send(
          RTCDataChannelMessage(
            json.encode(res),
          ),
        );
      },
      onError: (error, stackTrace) {
        debugPrint('Error: $error');
        _dataChannel?.send(
          RTCDataChannelMessage(
            json.encode(
              {'done': false},
            ),
          ),
        );
      },
    );
  }

  void onModelReady(String roomId) {
    setState(ViewState.BUSY);
    _socket = io.io(Environment.wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();
    _socket.emit('join room', roomId);
    _socket.on('other user', (data) {
      otherUserId = data;
      callUser();
    });
    _socket.on('user joined', (userId) {
      otherUserId = userId;
    });
    _socket.on('offer', (data) => _handleOffer(data));
    _socket.on('answer', (data) => _handleAnswer(data));
    _socket.on(
      'ice-candidate',
      (data) => _handleNewICECandidateData(data),
    );
    _socket.on('data', (data) {});
    setState(ViewState.IDLE);
  }

  void onModelDestroy() {
    _dataChannel?.close();
    _peerConnection?.close();
  }
}
