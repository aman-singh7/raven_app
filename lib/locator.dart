import 'package:cheap_share/viewmodel/data_channel_viewmodel.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

Future<void> setUpLocator() async {
  locator.registerFactory<DataChannelViewModel>(() => DataChannelViewModel());
}
