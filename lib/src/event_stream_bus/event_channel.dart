import 'dart:async';

class EventSubcriber<T> {
  bool _toDelete = false;
  String? _name;
  void Function()? _cancel;
  void Function(String topic, T event, {String? publisherName})? _fun;
  void cancel() {
    _fun = null;

    ///for not call if we cancel listen
    onDone = null;
    _cancel?.call();
  }

  ///call then channel destroy
  void Function()? onDone;
  EventSubcriber._(this._name, this._cancel, this._fun);
}

//FIXME: Add test when first create listener and whe first create publisher
class EventChannel<T> {
  final String topic;

  ///for _channelWorker
  final Map<StreamController<T>, StreamSubscription<T>> _publishers = {};

  ///key=hashCode
  Map<int, EventSubcriber<T>> _subcribers = {};
  EventChannel(
      this.topic /*,
      {StreamController<T>? publisher, String? publisherNam}*/
      ) {
    print('EventChannel ${T.runtimeType}: $topic CREATE');
    // if (publisher != null) addPublisher(publisher, publisherName: publisherNam);
  }

  void addPublisher(StreamController<T> publisher, {String? publisherName}) {
    if (!_publishers.containsKey(publisher)) {
      _publishers[publisher] = publisher.stream.listen(((event) {
        _channelWorker(event, publisherName: publisherName);
      }));
    }
    //FIXME: check if stream done remove subscribers and field in _publishers
  }

  EventSubcriber listen(String topic,
      {String? listenerName,
      required void Function(String topic, T event, {String? publisherName})
          fun}) {
    var s = EventSubcriber._(listenerName, null, fun);
    _subcribers[s.hashCode] = s;
    s._cancel = () {
      s._toDelete = true;
    };

    return s;
  }

  ///call when data come from publishers
  void _channelWorker(T data, {String? publisherName}) async {
    List<int> toDelete = [];
    _subcribers.forEach((key, value) {
      if (value._toDelete) {
        toDelete.add(key);
      } else {
        value._fun?.call(topic, data, publisherName: publisherName);
      }
    });
    if (toDelete.isNotEmpty) {
      toDelete.forEach((element) {
        _subcribers[element]?.onDone?.call();
        _subcribers.remove(element);
      });
    }
  }
}
