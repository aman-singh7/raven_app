import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class JoinRoom extends StatelessWidget {
  const JoinRoom({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('To be implemented'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          IO.Socket socket = IO.io('<SERVER-URL>', <String, dynamic>{
            'transports': ['websocket'],
            'autoConnect': false,
          });
          socket.connect();
          socket.emit('test');
          socket.emit(
            'join room',
            'a1c5ab40-a212-11ec-aa18-79b542415d64',
          );
          socket.on('all users', (data) {
            print('personal socket id: ${socket.id}');
            print('all users: ${data[0]}');
            print('users length: ${data.length}');
          });
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
