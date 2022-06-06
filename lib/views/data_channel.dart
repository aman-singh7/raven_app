import 'dart:core';

import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/data_channel_viewmodel.dart';
import 'package:cheap_share/views/base_view.dart';
import 'package:cheap_share/views/home.dart';
import 'package:flutter/material.dart';

class DataChannel extends StatelessWidget {
  static String tag = 'data_channel_sample';
  final String roomId;
  const DataChannel({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Channel Test'),
      ),
      body: BaseView<DataChannelViewModel>(
        onModelReady: (model) {
          model.onModelReady(roomId);
        },
        onModelDestroy: (model) {
          model.onModelDestroy();
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

          return Center(
            child: Text(
              model.otherUserId?.isEmpty ?? true
                  ? 'Waiting for other user to connect'
                  : 'Connected user id: ${model.otherUserId}',
            ),
          );
        },
      ),
    );
  }
}
