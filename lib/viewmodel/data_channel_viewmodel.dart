import 'package:cheap_share/viewmodel/base_viewmodel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DataChannelViewModel extends BaseViewModel {
  void onModelReady(String roomId) {
    IO.Socket socket = IO.io('http://192.168.137.177:8000/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.emit('test');
    socket.emit('join room', roomId);
    socket.on('all users', (data) {
      print('personal socket id: ${socket.id}');
      print('all users: ${data[0]}');
      print('users length: ${data.length}');
    });
  }
}
