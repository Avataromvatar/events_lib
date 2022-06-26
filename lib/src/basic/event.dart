import 'dart:async';

abstract class IEventInfo {
  Type get eventType;
  String? get eventName;
  String get fullEventName;
  bool get isClosed;
}

///при создании, регестрируется на шине по fullEventName. Если bus неуказана то к глобальной иначе к bus
abstract class IEventTransmitter<T> implements StreamSink<T>, IEventInfo {
  // IEventTransmitter({EventBus? bus, String? name});
  bool get hasReceiver;
  Future<void> connect(IEventReceiver<T> receiver);
  Future<void> disconnect(IEventReceiver<T> receiver);
}

///при создании подключается к шине которая в свою очередь подклюает напрямую к событию
abstract class IEventReceiver<T> implements StreamSubscription<T>, IEventInfo {
  // IEventReceiver({EventBus? bus, String? name, void Function(T event)? onData,Function? onError, void Function()? onDone, bool? cancelOnError});
  StreamController<T> _streamController = StreamController<T>.broadcast();
  // Type get eventType;
  // String? get eventName;
  // String get fullEventName;
  bool get hasTransmitter;
}

///
class EventTransmitter<T> implements IEventTransmitter<T> {
  Type get eventType => T..runtimeType;
  String? _eventName;
  String? get eventName => _eventName;
  String get fullEventName => '$eventType@$eventName';
  // bool _hasReceiver = false;
  bool _isClosed = false;
  bool get isClosed => _isClosed;
  bool get hasReceiver => _receivers.isNotEmpty;
  bool _isBusy = false;
  bool _isDeletengRecivers = false;
  final List<IEventReceiver<T>> _receivers =
      List<IEventReceiver<T>>.empty(growable: true);
  final List<IEventReceiver<T>> _receiversToDelete =
      List<IEventReceiver<T>>.empty(growable: true);

  // StreamController<T> _streamController = StreamController<T>.broadcast();

  @override
  void add(T event) async {
    if (!isClosed) await _send(event);
    // TODO:
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }
  @override
  Future addStream(Stream<T> stream) async {
    // TODO: implement addStream
    throw UnimplementedError();
  }

  @override
  Future close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // TODO: implement done
  Future get done => throw UnimplementedError();

  Future<void> _send(T event) async {
    if (_isBusy) {
      await Future.doWhile(() => _isBusy);

      _disconnectAllWhatNeeds();
    }

    _isBusy = true;

    await Future.forEach<IEventReceiver<T>>(_receivers, ((element) {
      // if(!_receiversToDelete.contains(element))
      element._streamController.add(event);
    }));
    _isBusy = false;
    // _disconnect();
  }

  void _disconnectAllWhatNeeds() {
    _isDeletengRecivers = true;
    _receivers.removeWhere((element) => _receiversToDelete.contains(element));
    _receiversToDelete.clear();
    _isDeletengRecivers = false;
  }

  Future<void> connect(IEventReceiver<T> receiver) async {
    _receivers.add(receiver);
  }

  Future<void> disconnect(IEventReceiver<T> receiver) async {
    if (_isDeletengRecivers) {
      await Future.doWhile(() => _isDeletengRecivers);
    }
    if (!_isBusy) {
      _receivers.remove(receiver);
    } else {
      _receiversToDelete.add(receiver);
    }
  }
}

class Test {
  String body = 'dfsdf';
}

void main() {
  EventTransmitter<Test> es = EventTransmitter<Test>();
  print(es.eventType);
}
