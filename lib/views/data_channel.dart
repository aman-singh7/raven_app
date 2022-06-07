import 'dart:core';

import 'package:cheap_share/enums/view_state.dart';
import 'package:cheap_share/viewmodel/data_channel_viewmodel.dart';
import 'package:cheap_share/views/base_view.dart';
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
    return WillPopScope(
      onWillPop: () {
        return _showDialog(context);
      },
      child: Scaffold(
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

            if (model.otherUserId?.isEmpty ?? true) {
              return Center(
                child: Text(
                  'Waiting for the other peer to join. Share room id: $roomId',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              children: [
                const Spacer(),
                if (model.fileName?.isNotEmpty ?? false) ...[
                  const Icon(
                    Icons.file_present,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.2,
                    child: Text(
                      model.fileName ?? '',
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: () {
                      model.pickFile();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.attach_file_outlined),
                        SizedBox(width: 10),
                        Text('Pick File')
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (model.fileName?.isEmpty ?? true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select file first!!'),
                              ),
                            );
                            return;
                          }
                          model.sendFile();
                        },
                        iconSize: 40,
                        icon: const Icon(Icons.send),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showDialog(context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Channel'),
          content: const Text('Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value == null) return false;

      return value;
    });
  }
}
