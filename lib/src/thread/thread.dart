import 'dart:async';

import 'dart:isolate';

class _IsolateWorker<T, R> {
  Stream<R> stream;
  ReceivePort _receivePort = ReceivePort();
}

class IsolateWorker<T, R> implements StreamSink<R> {
  StreamController<T> _transmitter = StreamController<T>.broadcast();
  Stream<T> get streamFromWorker => _transmitter.stream;
  // StreamController<R> _receiver = StreamController<R>.broadcast();
  bool _isWork = false;
  bool get isWork => _isWork;

  ReceivePort _receivePort = ReceivePort();

  ///send to isolate
  SendPort? _sender;
  late final Function(Stream<R> stream, void Function(T data) emit,
      Function({R? data}) exit) _userWorker;
  late StreamSubscription _listener;
  late Isolate _isolate;

  ///worker function be call always then new data came in [_receiver].
  ///[exit] function call exit from Isolate then [worker] end operation
  IsolateWorker(
      Function(
              Stream<R> stream, Function(T data) emit, Function({R? data}) exit)
          worker,
      R? initData) {
    _userWorker = worker;

    // _receiver.stream.listen((event) {
    //   _sender?.send(event);
    // });
    Isolate.spawn<SendPort>(_worker, _receivePort.sendPort).then((value) {
      _isolate = value;
      _listener = _receivePort.listen((message) {
        if (_sender == null && message is SendPort) {
          _sender = message;
        } else {
          _transmitter.add(message);
        }
      }, onDone: () {
        _close();
      }, onError: (e) {
        _close();
      });
    });
  }

  void _close() {
    _isolate.kill();
  }

  @override
  void add(R event) {
    // TODO: implement add
  }
  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }
  @override
  Future addStream(Stream<R> stream) {
    // TODO: implement addStream
    throw UnimplementedError();
  }

  @override
  Future close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  Completer _completer = Completer();
  Future get done => _completer.future;
}

void _worker(SendPort p) async {
  // Send a SendPort to the main isolate so that it can send Data  to
  // this isolate.
  print('WORKER: INIT');
  final commandPort = ReceivePort();
  p.send(commandPort.sendPort);
  print('WORKER: SEND PORT');
  // StreamController<R> controller = StreamController<R>();
  // commandPort.listen((message) {
  //   controller.add(message);
  // });

  // _userWorker(controller.stream, (data) {
  //   p.send(data);
  // }, ({data}) {});
  // print('WORKER: DONE');
  // _close();
}
