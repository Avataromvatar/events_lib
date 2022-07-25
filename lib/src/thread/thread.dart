import 'dart:async';
import 'dart:isolate';

class _IsolateWorkerDone {
  bool done = true;
}

class _IsolateWorkerPing {
  bool fromInner = false;
}

class _IsolateWorkerData<T, R, D> {
  SendPort tx;
  D? initData;
  StreamController<R> receiver = StreamController.broadcast();
  StreamController<T> transmitter = StreamController.broadcast();
  Future<void> Function(
      Stream<R> fromExternal, StreamSink<T> toExternal, D? initMsg) worker;
  _IsolateWorkerData(
      {required this.tx, required this.initData, required this.worker});
  Future<void> run() async {
    await worker.call(receiver.stream, transmitter, initData);
  }
}

class IsolateWorker<T, R, D> implements StreamSink<R> {
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
  late _IsolateWorkerData<T, R, D> _isolateWorkerData;
  Function({String? name})? onExit;
  bool _isExit = false;
  bool get isExit => _isExit;
  String? name;
  IsolateWorker(
    Future<void> Function(
            Stream<R> fromExternal, StreamSink<T> toExternal, D? initMsg)
        worker, {
    D? initMsg,
    this.onExit,
    this.name,
  }) {
    _isolateWorkerData = _IsolateWorkerData<T, R, D>(
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
    Isolate.spawn<_IsolateWorkerData<T, R, D>>(
            _isolateWorker, _isolateWorkerData,
            debugName: name, paused: true) //<T, R>
        .then((value) {
      _isolate = value;

      _tmr = Timer.periodic(Duration(milliseconds: _timePing), _onTimerPing);
    });
  }
  void run({D? initData}) {
    _isolateWorkerData.initData = initData;
    _isolate?.resume(Capability());
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

void _isolateWorker<T, R, D>(_IsolateWorkerData<T, R, D> initData) async {
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
