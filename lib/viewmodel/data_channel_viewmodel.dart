import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/base_viewmodel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DataChannelViewModel extends BaseViewModel {
  late IO.Socket _socket;
  RTCPeerConnection? _peerConnection;
  bool isRoomFull = false;
  String? otherUserId;

  final configuration = <String, dynamic>{
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  final loopbackConstraints = <String, dynamic>{
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  void _onICECandidate(RTCIceCandidate candidate) async {
    if (candidate.candidate == null) return;

    final payload = {
      'target': otherUserId,
      'candidate': candidate.candidate,
    };
    _socket.emit('ice-candidate', payload);
  }

  void _onRenegotiationNeeded(String socketId) {
    _peerConnection!
        .createOffer()
        .then((offer) => _peerConnection!.setLocalDescription(offer))
        .then((_) async {
      final payload = {
        'target': socketId,
        'caller': _socket.id,
        'sdp': await _peerConnection!.getLocalDescription(),
      };
      _socket.emit("offer", payload);
    }).catchError(
      (err) {
        print("Error handling negotiation needed event $err");
      },
    );
  }

  void _handleNewICECandidate(Map<String, dynamic> incoming) {
    _peerConnection!
        .addCandidate(RTCIceCandidate(incoming['candidate'], null, null))
        .catchError((err) {
      print('Error while add new ice candidate: $err');
    });
  }

  void createConnection(List<String> socketIds) async {
    if (socketIds.isEmpty) return;

    _peerConnection = await createPeerConnection(
      configuration,
      loopbackConstraints,
    );
    _peerConnection!.onIceCandidate = _onICECandidate;
    _peerConnection!.onRenegotiationNeeded =
        () => _onRenegotiationNeeded(socketIds[0]);
    otherUserId = socketIds[0];
  }

  void onModelReady(String roomId) {
    setState(ViewState.BUSY);
    _socket = IO.io('http://192.168.137.177:8000/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();
    _socket.emit('test');
    _socket.emit('join room', roomId);
    _socket.on('other user', (data) {
      print('personal socket id: ${_socket.id}');
      print('users length: ${data.length}');
      createConnection(data);
    });
    _socket.on(
      'ice-candidate',
      (data) => _handleNewICECandidate(data),
    );
    _socket.on('room full', (data) {
      isRoomFull = true;
    });
    setState(ViewState.IDLE);
  }
}
