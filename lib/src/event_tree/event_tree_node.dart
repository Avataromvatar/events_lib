import 'dart:async';

import 'package:events_lib/src/event_tree/event_tree_dto.dart';

///Parallel
///Event -> Node -> ParallelEventBus -> Event -> OtherNode
///
enum EventDirection { up, down, parallel }

typedef EventTreeStreamHandler = dynamic Function(
    String name, EventDirection dir, dynamic data,
    {IEventTreeDTO dto});
typedef EventTreeParallelEventHandler = void Function(
    String name, EventDirection dir, dynamic data,
    {IEventTreeDTO dto});

abstract class IEventTreeNode {
  String get nameNode;
  set defaultHandler(EventTreeStreamHandler handler);
  set upHandler(EventTreeStreamHandler handler);
  set downHandler(EventTreeStreamHandler handler);
  set parallelHandler(EventTreeParallelEventHandler handler);
}

class EventTreeNode implements IEventTreeNode {
  final StreamController<EventTreeDTO> _upStream =
      StreamController<EventTreeDTO>.broadcast();
  final StreamController<EventTreeDTO> _downStream =
      StreamController<EventTreeDTO>.broadcast();
  final StreamController<EventTreeDTO> _parallelStream =
      StreamController<EventTreeDTO>.broadcast();

  String nameNode;
  EventTreeStreamHandler? defaultHandler;
  EventTreeStreamHandler? upHandler;
  EventTreeStreamHandler? downHandler;
  EventTreeParallelEventHandler? parallelHandler;

  final Map<Stream, StreamSubscription> _upStreamConnect =
      Map<Stream, StreamSubscription>();
  final Map<Stream, StreamSubscription> _downStreamConnect =
      Map<Stream, StreamSubscription>();
  final Map<Stream, StreamSubscription> _parallelStreamConnect =
      Map<Stream, StreamSubscription>();

  // EventTreeChannel(this.topic, this.defaultHandler,
  //     {this.downHandler, this.parallelHandler, this.upHandler}) {
  //   // upStream.stream.listen((event) { })
  // }
  EventTreeNode(this.nameNode) {
    ///FIXME: add registration to parallel event bus by topic
    // if (parallelHandler != null) {
    //   parallelHandler!.call(topic, dir, event);
    // } else {
    //   defaultHandler?.call(topic, dir, event);
    // }
  }

  ///send to up direction stream. You send event not trigged upHandler
  void sendUp(dynamic data) {}

  ///send to down direction stream. You send event not trigged downHandler
  void sendDown(dynamic data) {}

  ///send to parallel bidirection event bus. You send event not trigged parallelHandler
  void send(dynamic data) {}

  ///connect just up and down stream
  void connectNode(
    EventTreeNode node, {
    bool connectUpStream = true,
    bool connectDownStream = true,
  }) {
    if (connectUpStream) {
      _connectStream(EventDirection.up, node._upStream.stream);
    }
    if (connectDownStream) {
      _connectStream(EventDirection.down, node._downStream.stream);
    }
  }

  ///disconnect just up and down stream
  void disconnectNode(
    EventTreeNode node, {
    bool disconnectUpStream = true,
    bool disconnectDownStream = true,
  }) {
    if (disconnectUpStream) {
      _disconnectStream(EventDirection.up, node._upStream.stream);
    }
    if (disconnectDownStream) {
      _disconnectStream(EventDirection.down, node._downStream.stream);
    }
  }

  ///then you connect to parallel event bus you stream - channel will be listen you stream and call send(event) then you stream.add(event).
  ///And then channel get event from parallel event bus he just call handler
  ///
  void _connectStream(EventDirection dir, Stream<EventTreeDTO> stream) {
    switch (dir) {
      case EventDirection.up:
        _upStreamConnect[stream] = stream.listen((event) {
          var ret;
          if (upHandler != null) {
            ret = upHandler!.call(nameNode, dir, event.data, dto: event);
          } else {
            ret = defaultHandler?.call(nameNode, dir, event.data, dto: event);
          }
          event.path.add(nameNode);
          event.count++;
          if (ret != null) {
            event.data = ret;

            _upStream.add(event);
          }
        });
        break;
      case EventDirection.down:
        _downStreamConnect[stream] = stream.listen((event) {
          var ret;
          if (downHandler != null) {
            ret = downHandler!.call(nameNode, dir, event.data, dto: event);
          } else {
            ret = defaultHandler?.call(nameNode, dir, event.data, dto: event);
          }
          event.path.add(nameNode);
          event.count++;
          if (ret != null) {
            event.data = ret;
            _downStream.add(ret);
          }
        });
        break;
      case EventDirection.parallel:
        _parallelStreamConnect[stream] = stream.listen((event) {
          send(event);
        });
        break;
      default:
    }
  }

  void _disconnectStream(EventDirection dir, Stream<EventTreeDTO> stream) {
    switch (dir) {
      case EventDirection.up:
        if (_upStreamConnect.containsKey(stream)) {
          _upStreamConnect[stream]?.cancel();
          _upStreamConnect.remove(stream);
        }
        break;
      case EventDirection.down:
        if (_downStreamConnect.containsKey(stream)) {
          _downStreamConnect[stream]?.cancel();
          _downStreamConnect.remove(stream);
        }
        break;
      case EventDirection.parallel:
        if (_parallelStreamConnect.containsKey(stream)) {
          _parallelStreamConnect[stream]?.cancel();
          _parallelStreamConnect.remove(stream);
        }
        break;
      default:
    }
  }
}
