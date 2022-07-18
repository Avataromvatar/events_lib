import 'dart:async';

import 'package:events_lib/src/thread/thread.dart';

Future<void> main() async {
  var thread =
      IsolateWorker<String, String>(_worker, initMsg: "Init", onExit: ({name}) {
    print("Tread $name EXIT");
  }, name: "alalall");
  thread.stream.listen((event) {
    print('From Isolate $event');
  });
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

Future<void> _worker(Stream<String> fromExternal, StreamSink<String> toExternal,
    String? initMsg) async {
  int c = 0;
  await for (var item in fromExternal) {
    toExternal.add(item.toUpperCase());
    c++;
    if (c == 3) break;
  }
}
