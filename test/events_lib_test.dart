import 'package:events_lib/events_lib.dart';
import 'package:events_lib/src/basic/event.dart';
import 'package:test/test.dart';

class TestAA {
  int d = 0;
}

class Test<T> {
  T? data;
  Test() {
    print(T.runtimeType.hashCode);
  }
}

Future<void> main() async {
  group('A group of tests', () {
    int tmp = 0;
    EventManager manager = EventManager();
    IEventTransmitter<TestAA> es =
        IEventTransmitter<TestAA>(eventNode: manager);
    IEventTransmitter es1 =
        IEventTransmitter(eventName: 'test', eventNode: manager);
    IEventReceiver<TestAA> er = IEventReceiver<TestAA>(eventNode: manager);
    er.listen((event) {
      print('TestAA: ${event.d}');
      tmp = event.d;
    });
    IEventReceiver er1 =
        IEventReceiver<Test>(eventName: 'test', eventNode: manager);

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () async {
      es.add(TestAA()..d = 1);
      await Future.delayed(Duration(milliseconds: 50));

      expect(tmp, 1);
    });
  });
}
