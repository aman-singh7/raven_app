import 'dart:core';
import 'dart:typed_data';

import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/data_channel_viewmodel.dart';
import 'package:cheap_share/views/base_view.dart';
import 'package:cheap_share/views/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class DataChannel extends StatefulWidget {
  static String tag = 'data_channel_sample';
  final String roomId;
  const DataChannel({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  _DataChannelState createState() => _DataChannelState();
}

class _DataChannelState extends State<DataChannel> {
  RTCPeerConnection? _peerConnection;
  bool _inCalling = false;

  RTCDataChannelInit? _dataChannelDict;
  RTCDataChannel? _dataChannel;

  String _sdp = '';

  void _onSignalingState(RTCSignalingState state) {
    print(state);
  }

  void _onIceGatheringState(RTCIceGatheringState state) {
    print(state);
  }

  void _onIceConnectionState(RTCIceConnectionState state) {
    print(state);
  }

  void _onCandidate(RTCIceCandidate candidate) {
    print('onCandidate: ${candidate.candidate}');
    _peerConnection?.addCandidate(candidate);
    setState(() {
      _sdp += '\n';
      _sdp += candidate.candidate ?? '';
    });
  }

  void _onRenegotiationNeeded() {
    print('RenegotiationNeeded');
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

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    final offerSdpConstraints = <String, dynamic>{
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };

    final loopbackConstraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    if (_peerConnection != null) return;

    try {
      _peerConnection =
          await createPeerConnection(configuration, loopbackConstraints);

      _peerConnection!.onSignalingState = _onSignalingState;
      _peerConnection!.onIceGatheringState = _onIceGatheringState;
      _peerConnection!.onIceConnectionState = _onIceConnectionState;
      _peerConnection!.onIceCandidate = _onCandidate;
      _peerConnection!.onRenegotiationNeeded = _onRenegotiationNeeded;

      _dataChannelDict = RTCDataChannelInit();
      _dataChannelDict!.id = 1;
      _dataChannelDict!.ordered = true;
      _dataChannelDict!.maxRetransmitTime = -1;
      _dataChannelDict!.maxRetransmits = -1;
      _dataChannelDict!.protocol = 'sctp';
      _dataChannelDict!.negotiated = false;

      _dataChannel = await _peerConnection!
          .createDataChannel('dataChannel', _dataChannelDict!);
      _peerConnection!.onDataChannel = _onDataChannel;

      var description = await _peerConnection!.createOffer(offerSdpConstraints);
      print(description.sdp);
      await _peerConnection!.setLocalDescription(description);

      _sdp = description.sdp ?? '';
      //change for loopback.
      //description.type = 'answer';
      //_peerConnection.setRemoteDescription(description);
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  void _hangUp() async {
    try {
      await _dataChannel?.close();
      await _peerConnection?.close();
      _peerConnection = null;
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      _inCalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Channel Test'),
      ),
      body: BaseView<DataChannelViewModel>(
        onModelReady: (model) {
          model.onModelReady(widget.roomId);
        },
        builder: (context, model, child) {
          if (model.state == ViewState.BUSY) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (model.isRoomFull) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
              ),
            );
          }

          return OrientationBuilder(
            builder: (context, orientation) {
              return Center(
                child: Container(
                  child: _inCalling ? Text(_sdp) : Text('data channel test'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
