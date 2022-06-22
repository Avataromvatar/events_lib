import 'package:events_lib/events_lib.dart';
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

void main() {
  Test<TestAA> a = Test<TestAA>();

  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
