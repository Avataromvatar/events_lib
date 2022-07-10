import 'dart:async';

abstract class IEventPointInfo {
  ///event type
  Type get eventType;

  ///event name
  String? get eventName;

  ///for IEventBus
  String? get eventPrefix;

  ///event fullPath = [eventPrefix]/[eventType]@[eventName]
  String get fullEventName;
  bool get isClosed;
}

abstract class IEventPoint implements IEventPointInfo {
  bool get isInitialized;

  ///return false if point registrated in EventBus
  bool initialize({String? eventName, IEventManager eventBus});
  IEventTransmitter<T>? transmitter<T>();
  IEventReceiver<T>? receiver<T>();
}

///при создании, регестрируется на шине по fullEventName. Если bus неуказана то к глобальной иначе к bus
abstract class IEventTransmitter<T> implements StreamSink<T>, IEventPointInfo {
  // IEventTransmitter({EventBus? bus, String? name});
  bool get hasReceiver;
  set onReceiver(void Function(void Function(T data) toNewReciver));
  Future<void> connect(IEventReceiver<T> receiver);
  Future<void> disconnect(IEventReceiver<T> receiver);

  ///if stream added, you can remove it
  Future removeStream(Stream<T> stream);

  factory IEventTransmitter({String? eventName, IEventNode? eventNode}) {
    var et = EventTransmitter<T>();
    et._eventName = eventName;
    if (eventNode != null) {
      eventNode.register(transmitter: et);
    } else {
      //TODO: connect to global EventManager
    }
    return et;
  }
}

///при создании подключается к шине которая в свою очередь подклюает напрямую к событию
abstract class IEventReceiver<T>
    implements StreamSubscription<T>, IEventPointInfo {
  // IEventReceiver({EventBus? bus, String? name, void Function(T event)? onData,Function? onError, void Function()? onDone, bool? cancelOnError});
  StreamController<T>
      get _streamController; // = StreamController<T>.broadcast();
  Stream<T> get stream;
  bool get hasTransmitter;

  /// Adds a subscription to this stream.
  ///
  /// Returns a [IEventReceiver] which handles events from this stream using
  /// the provided [onData], [onError] and [onDone] handlers.
  /// The handlers can be changed on the subscription, but they start out
  /// as the provided functions.
  ///
  /// On each data event from this stream, the subscriber's [onData] handler
  /// is called. If [onData] is `null`, nothing happens.
  ///
  /// On errors from this stream, the [onError] handler is called with the
  /// error object and possibly a stack trace.
  ///
  /// The [onError] callback must be of type `void Function(Object error)` or
  /// `void Function(Object error, StackTrace)`.
  /// The function type determines whether [onError] is invoked with a stack
  /// trace argument.
  /// The stack trace argument may be [StackTrace.empty] if this stream received
  /// an error without a stack trace.
  ///
  /// Otherwise it is called with just the error object.
  /// If [onError] is omitted, any errors on this stream are considered unhandled,
  /// and will be passed to the current [Zone]'s error handler.
  /// By default unhandled async errors are treated
  /// as if they were uncaught top-level errors.
  ///
  /// If this stream closes and sends a done event, the [onDone] handler is
  /// called. If [onDone] is `null`, nothing happens.
  ///
  /// If [cancelOnError] is `true`, the subscription is automatically canceled
  /// when the first error event is delivered. The default is `false`.
  ///
  /// While a subscription is paused, or when it has been canceled,
  /// the subscription doesn't receive events and none of the
  /// event handler functions are called.
  IEventReceiver<T> listen(
    void onData(T event)?, {
    Function? onError,
    void onDone()?,
    bool cancelOnError = false,
  });

  static IEventReceiver<A> listenOf<A>(
      {String? nameEvent,
      void onData(A event)?,
      Function? onError,
      void onDone()?,
      bool cancelOnError = false,
      IEventNode? eventManager}) {
    var ret = EventReceiver<A>();
    ret._eventName = nameEvent;
    if (eventManager != null) {
      eventManager.register(receiver: ret);
    }
    return ret.listen(onData,
        onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  ///then transmitter connect to reciver add +1 (true) if disconnect -1 (false)
  void _transmitterCount(bool add);
}

abstract class IEventNode {
  void register({IEventTransmitter? transmitter, IEventReceiver? receiver});
  void unregister({IEventTransmitter? transmitter, IEventReceiver? receiver});
  bool send<T>(T data, {String? eventName});

  ///получить список всех событий. если  needFullPath = 0 то список будет содержать только имена событий(null ignore), а иначе полный путь(с типом)
  List<String> getEventList({bool needFullPath = false});
}

///Особенность менеджера что он настраивает только связи между передатчиками и приемниками и потом не учавствует в их взаимодействии.
///Передатчик хранит своих приемников и кидает им сообщение напрямую
abstract class IEventManager implements IEventNode {
  IEventTransmitter<T> getTransmitter<T>({String? name});
  IEventReceiver<T> getReceiver<T>({String? name});
}

///Особенность шины в том что она знает о передатчиках и подписчиках связывает их через себя, становляь единственным подписчиком у передатчика.
///к полнуму пути добавляется еще название шины: eventBusName/EventType@EventName
abstract class IEventBus implements IEventNode {
  String get name;
}

class EventReceiver<T> implements IEventReceiver<T> {
  EventReceiver() : super();
  int _count = 0;
  Type get eventType => T..runtimeType;
  String? _eventName;
  String? get eventName => _eventName;
  String? _eventPrefix;
  String? get eventPrefix => _eventPrefix;
  String? get _eventTypeAndName =>
      _eventName != null ? '$eventType@$eventName' : '$eventType';
  String get fullEventName => _eventPrefix != null
      ? '$_eventPrefix/$_eventTypeAndName'
      : '$_eventTypeAndName';
  // bool _hasReceiver = false;
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  bool _isClosed = false;
  bool get isClosed => _isClosed;
  bool _isInitialize = false;
  bool _asFutereOn = false;
  bool? _cancelOnError;
  StreamController<T> _streamController = StreamController<T>.broadcast();
  StreamSubscription<T>? _streamSubscription;
  Stream<T> get stream => _streamController.stream;
  void Function(T data)? _handleData;
  void Function()? _handleDone;
  Function? _handleError;
  Completer _completer = Completer();
  bool get hasTransmitter => _count > 0;
  void _transmitterCount(bool add) {
    if (add)
      _count++;
    else
      _count--;
  }

  @override
  void onData(void Function(T data)? handleData) {
    _handleData = handleData;
    _initialize();
  }

  @override
  void onDone(void Function()? handleDone) {
    _initialize();
    _handleDone = handleDone;
  }

  @override
  void onError(Function? handleError) {
    _initialize();
    _handleError = handleError;
  }

  @override
  IEventReceiver<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool cancelOnError = false}) {
    _handleData = onData;
    _handleDone = onDone;
    _handleError = onError;
    _cancelOnError = cancelOnError;
    _initialize();
    return this;
  }

  Future<void> _close({dynamic error, bool? thisIsDone}) async {
    await _streamSubscription?.cancel();
    _streamController.close();
    _isClosed = true;
    if (_asFutereOn) {
      _completer.complete();
    } else {
      if (error != null) _handleError?.call(error);
      if (thisIsDone ?? false) _handleDone?.call();
    }
  }

  void _initialize() {
    if (!_isInitialize) {
      _streamSubscription = _streamController.stream.listen((event) {
        _handleData?.call(event);
      }, onDone: () {
        _close(thisIsDone: true);
      }, onError: (e) {
        if (_cancelOnError ?? false) _close(error: e);
      });
      _isInitialize = true;
    }
  }

  @override
  Future<void> cancel() async {
    await _close();
    return;

    // throw UnimplementedError();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) async {
    _asFutereOn = true;
    _initialize();
    await _completer.future;

    return futureValue ?? null as E;
    // throw UnimplementedError();
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    _streamSubscription?.pause(resumeSignal);
  }

  @override
  void resume() {
    _streamSubscription?.resume();
  }
}

///
class EventTransmitter<T> implements IEventTransmitter<T> {
  Type get eventType => T..runtimeType;
  String? _eventName;
  String? get eventName => _eventName;
  String? _eventPrefix;
  String? get eventPrefix => _eventPrefix;
  String? get _eventTypeAndName =>
      _eventName != null ? '$eventType@$eventName' : '$eventType';
  String get fullEventName => _eventPrefix != null
      ? '$_eventPrefix/$_eventTypeAndName'
      : '$_eventTypeAndName';
  // bool _hasReceiver = false;
  bool _isClosed = false;
  bool get isClosed => _isClosed;
  bool get hasReceiver => _receivers.isNotEmpty;
  bool _isBusy = false;
  bool _isDeletingRecivers = false;
  bool _isInitialize = false;

  final List<IEventReceiver<T>> _receivers =
      List<IEventReceiver<T>>.empty(growable: true);
  final List<IEventReceiver<T>> _receiversToDelete =
      List<IEventReceiver<T>>.empty(growable: true);
  final Map<Stream<T>, StreamSubscription<T>> _addStreams = {};
  final Completer _completer = Completer();
  void Function(void Function(T data) toNewReciver)? _onReceiver;
  // StreamController<T> _streamController = StreamController<T>.broadcast();
  @override
  set onReceiver(void Function(void Function(T data) toNewReciver) func) {
    _onReceiver = func;
  }

  @override
  void add(T event) async {
    if (!isClosed) {
      await _send(event);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }
  @override
  Future addStream(Stream<T> stream) async {
    if (_addStreams.containsKey(stream)) return;
    _addStreams[stream] = stream.listen(
      (event) {
        add(event);
      },
      onDone: () {
        _addStreams.remove(stream);
      },
    );

    // throw UnimplementedError();
  }

  @override
  Future removeStream(Stream<T> stream) async {
    if (_addStreams.containsKey(stream)) {
      await _addStreams[stream]?.cancel();
      _addStreams.remove(stream);
    }
  }

  @override
  Future close() async {
    _isClosed = true;
    await Future.doWhile(() => _isBusy);
    _receivers.forEach((element) {
      element.cancel();
    });
    _receivers.clear();
    _receiversToDelete.clear();
    _addStreams.forEach((key, value) {
      value.cancel();
    });
    _addStreams.clear();
    _completer.complete();
    // throw UnimplementedError();
  }

  @override
  // TODO: implement done
  Future get done => _completer.future; //throw UnimplementedError();

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
    _isDeletingRecivers = true;
    _receivers.removeWhere((element) => _receiversToDelete.contains(element));
    _receiversToDelete.clear();
    _isDeletingRecivers = false;
  }

  Future<void> connect(IEventReceiver<T> receiver) async {
    if (_receivers.contains(receiver)) return;
    _receivers.add(receiver);
    receiver._transmitterCount(true);
    _onReceiver?.call(((data) {
      receiver._streamController.add(data);
    }));
  }

  Future<void> disconnect(IEventReceiver<T> receiver) async {
    if (_isDeletingRecivers) {
      await Future.doWhile(() => _isDeletingRecivers);
    }
    if (!_isBusy) {
      _receivers.remove(receiver);
      receiver._transmitterCount(false);
    } else {
      _receiversToDelete.add(receiver);
      receiver._transmitterCount(false);
    }
  }
}

class Test {
  String body = 'dfsdf';
}

void main() {
  EventTransmitter<Test> es = EventTransmitter<Test>();
  EventTransmitter es1 = EventTransmitter();
  print(es.eventType);
  print(es1.eventType);
}
