import 'dart:async';
import 'dart:isolate';

class _IsolateWorkerDone {
  bool done = true;
}

class _IsolateWorkerPing {
  bool fromInner = false;
}

class _IsolateWorkerData<T, R> {
  SendPort tx;
  T? initData;
  StreamController<R> receiver = StreamController.broadcast();
  StreamController<T> transmitter = StreamController.broadcast();
  Future<void> Function(
      Stream<R> fromExternal, StreamSink<T> toExternal, T? initMsg) worker;
  _IsolateWorkerData(
      {required this.tx, required this.initData, required this.worker});
  Future<void> run() async {
    await worker.call(receiver.stream, transmitter, initData);
  }
}

class IsolateWorker<T, R> implements StreamSink<R> {
  Isolate? _isolate;
  ReceivePort _receivePort = ReceivePort();
  SendPort? _sendToIsolate;
  StreamController<T> _transmitter = StreamController<T>.broadcast();
  Stream<T> get stream => _transmitter.stream;
  //Ping Section
  Timer? _tmr;
  int _timePing = 500;
  bool _pingFlag = false;
  _IsolateWorkerPing _ping = _IsolateWorkerPing();
  //
  late _IsolateWorkerData<T, R> _isolateWorkerData;
  Function({String? name})? onExit;
  bool _isExit = false;
  bool get isExit => _isExit;
  String? name;
  IsolateWorker(
      Future<void> Function(
              Stream<R> fromExternal, StreamSink<T> toExternal, T? initMsg)
          worker,
      {T? initMsg,
      this.onExit,
      this.name}) {
    _isolateWorkerData = _IsolateWorkerData<T, R>(
        initData: initMsg, tx: _receivePort.sendPort, worker: worker);

    ///Подписываемся на соообщения из изолята
    _receivePort.listen((message) {
      if (_sendToIsolate == null && message is SendPort) {
        print('Extern: get send port');
        _sendToIsolate = message;
      } else {
        if (message is _IsolateWorkerPing) {
          _ping.fromInner = true;
        } else {
          if (message is _IsolateWorkerDone) {
            close();
          } else {
            _transmitter.add(message);
          }
        }
      }
    });

    ///
    Isolate.spawn<_IsolateWorkerData<T, R>>(_isolateWorker, _isolateWorkerData,
            debugName: name) //<T, R>
        .then((value) {
      _isolate = value;

      _tmr = Timer.periodic(Duration(milliseconds: _timePing), _onTimerPing);
    });
  }
  void _onTimerPing(Timer tmr) {
    if (_pingFlag) {
      if (!_ping.fromInner) {
        //TODO: errror
        print('Worker Freeze!!!');
        close();
      } else {
        _pingFlag = false;
        _ping.fromInner = false;
      }
    } else {
      _pingFlag = true;
      _sendToIsolate?.send(_ping);
    }
  }

  @override
  void add(R event) {
    _sendToIsolate?.send(event);
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
  Future close() async {
    _isExit = true;
    _isolate?.kill(priority: 0);
    _tmr?.cancel();
    onExit?.call(name: name);
  }

  Completer _completer = Completer();
  Future get done => _completer.future;
}

void _isolateWorker<T, R>(_IsolateWorkerData<T, R> initData) async {
  // Send a SendPort to the main isolate so that it can send Data  to
  // this isolate.
  print('WORKER: INIT: ${T..toString()} ${R..toString()}');
  final commandPort = ReceivePort();
  initData.tx.send(commandPort.sendPort);

  commandPort.listen((message) {
    if (message is _IsolateWorkerPing) {
      initData.tx.send(message..fromInner = true);
    } else {
      initData.receiver.add(message);
    }
  });
  initData.transmitter.stream.listen((event) {
    initData.tx.send(event);
  });
  await initData.run();
  initData.tx.send(_IsolateWorkerDone());
}
// void _isolateWorker<T, R>(_IsolateWorkerData<T, R> initData) async {
//   // Send a SendPort to the main isolate so that it can send Data  to
//   // this isolate.
//   print('WORKER: INIT');
//   final commandPort = ReceivePort();
//   initData.tx.send(commandPort.sendPort);
//   StreamController<R> receiver = StreamController<R>.broadcast();
//   StreamController<T> transmitter = StreamController<T>.broadcast();
//   commandPort.listen((message) {
//     if (message is R) {
//       receiver.add(message);
//     } else {
//       if (message is _IsolateWorkerPing) {
//         initData.tx.send(message..fromInner = true);
//       }
//     }
//   });
//   transmitter.stream.listen((event) {
//     if (event is T) {
//       initData.tx.send(event);
//     }
//   });

//   await initData.worker.call(receiver.stream, transmitter, initData.initData);
// }


// class _IsolateWorker<T, R> {
//   ///по которому мы получаем данные
//   late StreamController<R> receiver = StreamController<R>.broadcast();
//   late StreamController<T> transmitter = StreamController<T>.broadcast();
//   ReceivePort _receivePort = ReceivePort();
//   Function(Stream<R> fromExternal, StreamSink<T> toExternal) worker;
//   _IsolateWorker(this.worker) {}
// }

// class IsolateWorker<T, R> implements StreamSink<R> {
//   StreamController<T> _transmitter = StreamController<T>.broadcast();
//   late _IsolateWorker<T, R> _isolateWorker;
//   Isolate? _isolate;
//   IsolateWorker(
//       Function(Stream<R> fromExternal, StreamSink<T> toExternal) worker) {
//     _isolateWorker = _IsolateWorker(worker);

//     Isolate.spawn<_IsolateWorker>(_worker, _isolateWorker)
//         .then((value) => _isolate = value);
//   }
// }

// class IsolateWorker<T, R> implements StreamSink<R> {
//   StreamController<T> _transmitter = StreamController<T>.broadcast();
//   Stream<T> get streamFromWorker => _transmitter.stream;
//   // StreamController<R> _receiver = StreamController<R>.broadcast();
//   bool _isWork = false;
//   bool get isWork => _isWork;

//   ReceivePort _receivePort = ReceivePort();

//   ///send to isolate
//   SendPort? _sender;
//   late final Function(Stream<R> stream, void Function(T data) emit,
//       Function({R? data}) exit) _userWorker;
//   late StreamSubscription _listener;
//   late Isolate _isolate;

//   ///worker function be call always then new data came in [_receiver].
//   ///[exit] function call exit from Isolate then [worker] end operation
//   IsolateWorker(
//       Function(
//               Stream<R> stream, Function(T data) emit, Function({R? data}) exit)
//           worker,
//       R? initData) {
//     _userWorker = worker;

//     // _receiver.stream.listen((event) {
//     //   _sender?.send(event);
//     // });
//     Isolate.spawn<SendPort>(_worker, _receivePort.sendPort).then((value) {
//       _isolate = value;
//       _listener = _receivePort.listen((message) {
//         if (_sender == null && message is SendPort) {
//           _sender = message;
//         } else {
//           _transmitter.add(message);
//         }
//       }, onDone: () {
//         _close();
//       }, onError: (e) {
//         _close();
//       });
//     });
//   }

//   void _close() {
//     _isolate.kill();
//   }

//   @override
//   void add(R event) {
//     // TODO: implement add
//   }
//   @override
//   void addError(Object error, [StackTrace? stackTrace]) {
//     // TODO: implement addError
//   }
//   @override
//   Future addStream(Stream<R> stream) {
//     // TODO: implement addStream
//     throw UnimplementedError();
//   }

//   @override
//   Future close() {
//     // TODO: implement close
//     throw UnimplementedError();
//   }

//   Completer _completer = Completer();
//   Future get done => _completer.future;
// }

// void _worker(_IsolateWorker isoWorker) async {
//   // Send a SendPort to the main isolate so that it can send Data  to
//   // this isolate.
//   print('WORKER: INIT');
//   final commandPort = ReceivePort();
//   // p.send(commandPort.sendPort);
//   print('WORKER: SEND PORT');
//   // StreamController<R> controller = StreamController<R>();
//   // commandPort.listen((message) {
//   //   controller.add(message);
//   // });

//   // _userWorker(controller.stream, (data) {
//   //   p.send(data);
//   // }, ({data}) {});
//   // print('WORKER: DONE');
//   // _close();
// }
