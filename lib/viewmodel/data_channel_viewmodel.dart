import 'dart:typed_data';

import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/base_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class DataChannelViewModel extends BaseViewModel {
  late io.Socket _socket;
  RTCPeerConnection? _peerConnection;
  bool isRoomFull = false;
  String? _otherUserId;
  RTCDataChannelInit? _dataChannelDict;
  RTCDataChannel? _dataChannel;

  String _sdp = '';

  String? get otherUserId => _otherUserId;

  set otherUserId(String? id) {
    _otherUserId = id;
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
    };
    _socket.emit('ice-candidate', payload);
    _sdp += '\n';
    _sdp += candidate.candidate ?? '';
  }

  void _onIceGatheringState(RTCIceGatheringState state) {
    print('Gathering state: ${state.toString()}');
  }

  void _onIceConnectionState(RTCIceConnectionState state) {
    print('Gathering state: ${state.toString()}');
  }

  void _onRenegotiationNeeded(String socketId) async {
    try {
      final offer = await _peerConnection!.createOffer();
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

  void _handleNewICECandidate(Map<String, dynamic> incoming) {
    _peerConnection!
        .addCandidate(RTCIceCandidate(incoming['candidate'], null, null))
        .catchError((err) {
      print('Error while add new ice candidate: $err');
    });
  }

  void _onSignalingState(RTCSignalingState state) {
    debugPrint('signaling state index: ${state.index}, name: ${state.name}');
  }

  // void createConnection(List<String> socketIds) async {
  //   if (socketIds.isEmpty) return;

  //   try {
  //     _peerConnection = await createPeerConnection(
  //       configuration,
  //       loopbackConstraints,
  //     );
  //     _peerConnection!.onSignalingState = _onSignalingState;
  //     _peerConnection!.onIceCandidate = _onICECandidate;
  //     _peerConnection!.onIceGatheringState = _onIceGatheringState;
  //     _peerConnection!.onIceConnectionState = _onIceConnectionState;
  //     _peerConnection!.onRenegotiationNeeded =
  //         () => _onRenegotiationNeeded(socketIds[0]);

  //     _dataChannelDict = RTCDataChannelInit();
  //     _dataChannelDict!.id = 1;
  //     _dataChannelDict!.ordered = true;
  //     _dataChannelDict!.maxRetransmitTime = -1;
  //     _dataChannelDict!.maxRetransmits = -1;
  //     _dataChannelDict!.protocol = 'sctp';
  //     _dataChannelDict!.negotiated = false;

  //     _dataChannel = await _peerConnection!
  //         .createDataChannel('dataChannel', _dataChannelDict!);
  //     _peerConnection!.onDataChannel = _onDataChannel;

  //     var description = await _peerConnection!.createOffer(offerSdpConstraints);
  //     print(description.sdp);
  //     await _peerConnection!.setLocalDescription(description);

  //     _sdp = description.sdp ?? '';
  //     //change for loopback.
  //     //description.type = 'answer';
  //     //_peerConnection.setRemoteDescription(description);
  //   } catch (err) {
  //     debugPrint(err.toString());
  //   }

  //   otherUserId = socketIds[0];
  // }

  void callUser() async {
    _peerConnection = await createPeer();

    _dataChannelDict = RTCDataChannelInit();
    _dataChannelDict!.id = 1;
    _dataChannelDict!.ordered = true;
    _dataChannelDict!.maxRetransmitTime = -1;
    _dataChannelDict!.maxRetransmits = -1;
    _dataChannelDict!.protocol = 'sctp';
    _dataChannelDict!.negotiated = false;
    await _peerConnection!.createDataChannel('dataChannel', _dataChannelDict!);

    _peerConnection!.onDataChannel = _onDataChannel;
  }

  Future<RTCPeerConnection> createPeer() async {
    final _peer = await createPeerConnection(_configuration);
    _peerConnection!.onIceCandidate = _onICECandidate;
    _peerConnection!.onRenegotiationNeeded =
        () => _onRenegotiationNeeded(_otherUserId ?? '');

    return _peer;
  }

  void _handleOffer(data) async {
    _peerConnection ??= await createPeer();
    _peerConnection!.onDataChannel = _onDataChannel;

    try {
      final desc = await _peerConnection!.createOffer();
      await _peerConnection!.setRemoteDescription(desc);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      final payload = {
        'target': _otherUserId,
        'caller': _socket.id,
        'sdp': answer.sdp,
        'type': answer.type,
      };

      _socket.emit('answer', payload);
    } catch (err) {
      debugPrint(err.toString());
    }
  }

  void _handleAnswer(data) async {
    final desc = RTCSessionDescription(data['spd'], data['type']);
    try {
      await _peerConnection!.setRemoteDescription(desc);
    } catch (err) {
      debugPrint('Error occured while handeling answer ${err.toString()}');
    }
  }

  /// Send some sample messages and handle incoming messages.
  void _onDataChannel(RTCDataChannel dataChannel) {
    dataChannel.onMessage = (message) {
      if (message.type == MessageType.text) {
        print(message.text);
      } else {
        // do something with message.binary
      }
    };
    // or alternatively:
    dataChannel.messageStream.listen((message) {
      if (message.type == MessageType.text) {
        print(message.text);
      } else {
        // do something with message.binary
      }
    });

    dataChannel.send(RTCDataChannelMessage('Hello!'));
    dataChannel.send(RTCDataChannelMessage.fromBinary(Uint8List(5)));
  }

  void onModelReady(String roomId) {
    setState(ViewState.BUSY);
    _socket = io.io('http://192.168.43.235:8000/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();
    _socket.emit('join room', roomId);
    _socket.on('other user', (data) {
      otherUserId = data[0];
      callUser();
    });
    _socket.on('user joined', (userId) {
      otherUserId = userId;
    });
    _socket.on('offer', (data) => _handleOffer(data));
    _socket.on('answer', (data) => _handleAnswer(data));
    _socket.on(
      'ice-candidate',
      (data) => _handleNewICECandidate(data),
    );
    _socket.on('data', (data) {});
    _socket.on('room full', (data) {
      isRoomFull = true;
    });
    setState(ViewState.IDLE);
  }

  void onModelDestroy() {
    _dataChannel?.close();
    _peerConnection?.close();
  }
}
