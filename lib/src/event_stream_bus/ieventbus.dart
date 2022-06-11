import 'dart:async';

import 'package:events_lib/src/event_stream_bus/event_channel.dart';
import 'package:events_lib/src/event_stream_bus/event_node.dart';

abstract class IEventBus implements IEventNodeInfo {
  List<String> get topics;
  StreamController<T>? addTopic<T>(String topic,
      {StreamController<T>? stream, String? publisherName});
  EventSubcriber<T> listenTopic<T>(String topic,
      {String? subscriberName,
      required void Function(String topic, T event, {String? publisherName})
          fun});
  bool setEventNode(IEventNode enode);
}

class EventBusMixin implements IEventBus {
  IEventNode? __eventNode;
  String get name {
    if (__eventNode == null) __eventNode = EventNodeGlobal.instance;
    return __eventNode!.name;
  }

  List<String> get topics {
    if (__eventNode == null) __eventNode = EventNodeGlobal.instance;
    return __eventNode!.topics;
  }

  StreamController<T>? addTopic<T>(String topic,
      {StreamController<T>? stream, String? publisherName}) {
    if (__eventNode == null) __eventNode = EventNodeGlobal.instance;

    StreamController<T>? s;
    if (stream == null) {
      s = StreamController<T>.broadcast();
    } else {
      s = stream;
    }

    var c = __eventNode!.getEventChannel<T>(topic);
    if (c == null) //no topic
    {
      var ec = EventChannel<T>(topic);
      ec.addPublisher(s, publisherName: publisherName);
      __eventNode!.addEventChannel<T>(ec);
      //  return s;
    } else {
      c.addPublisher(s, publisherName: publisherName);
    }
    return s;
  }

  EventSubcriber<T> listenTopic<T>(String topic,
      {String? subscriberName,
      required void Function(String topic, T event, {String? publisherName})
          fun}) {
    if (__eventNode == null) __eventNode = EventNodeGlobal.instance;
    var ec = __eventNode!.getEventChannel<T>(topic);
    var ret;
    if (ec == null) //no topic
    {
      ec = EventChannel<T>(topic);
      ret = ec.listen(topic, fun: fun);
      __eventNode!.addEventChannel<T>(ec);
      //  return s;
    } else {
      ret = ec.listen(topic, fun: fun);
    }
    return ret;
  }

  ///if you whant use custom EventNode call this method first
  bool setEventNode(IEventNode enode) {
    if (__eventNode != null) return false;
    __eventNode = enode;
    return true;
  }
}
