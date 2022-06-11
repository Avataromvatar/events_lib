import 'dart:async';

import 'package:events_lib/src/event_stream_bus/event_channel.dart';

abstract class IEventNodeInfo {
  String get name;
  List<String> get topics;
}

abstract class IEventNode implements IEventNodeInfo {
  // String get name;
  // List<String> get topic;
  bool containsTopic(String topic);
  bool addEventChannel<T>(EventChannel<T> channel);
  // void removePublisher<T>(EventChannel<T> channel);
  EventChannel<T>? getEventChannel<T>(String topic);
}

class EventNodeGlobal implements IEventNode {
  static EventNodeGlobal instance = EventNodeGlobal._();
  EventNodeGlobal._() {
    print('EventNodeGlobal create');
  }
  factory EventNodeGlobal() {
    return instance;
  }

  ///key=topic
  Map<String, EventChannel> _channels = {};
  //------- IEventNode -------//
  String get name => 'EventNodeGlobal';
  List<String> get topics => _channels.keys.toList();
  bool containsTopic(String topic) {
    return _channels.containsKey(topic);
  }

  bool addEventChannel<T>(EventChannel<T> channel) {
    if (_channels.containsKey(channel.topic)) return false;
    _channels[channel.topic] = channel;
    return true;
  }

  // void removePublisher<T>(EventChannel<T> channel) {}
  EventChannel<T>? getEventChannel<T>(String topic) {
    if (_channels.containsKey(topic))
      return _channels[topic] as EventChannel<T>;
    return null;
  }
}
