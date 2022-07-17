import 'dart:async';

import 'package:events_lib/src/thread/thread.dart';

Future<void> main() async {
  var thread = IsolateWorker<String, String>((stream, emit, exit) async {
    await for (var item in stream) {
      print('From main thread: $item');
      emit.call(item.toUpperCase());
      if (item == 'exit') {
        exit.call(data: item.toUpperCase());
      }
    }
  }, '');
  int count = 0;
  Timer.periodic(Duration(seconds: 1), (timer) {
    count++;
    thread.add('count: $count');
    if (count > 10) {
      thread.add('exit');
    }
  });
  await Future.delayed(Duration(seconds: 12));
  print('Exit');
}
