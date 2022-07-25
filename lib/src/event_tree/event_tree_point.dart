// import 'dart:async';

// import 'package:events_lib/src/event_tree/event_tree_dto.dart';
// import 'package:events_lib/src/event_tree/event_tree_node.dart';

// class EventTreePoint<T> {
//   final StreamController<EventTreeDTO<T>> streamController =
//       StreamController<EventTreeDTO<T>>.broadcast();
//   final Map<EventTreePoint, StreamSubscription> connections =
//       Map<EventTreePoint, StreamSubscription>();

//   EventTreeStreamHandler? handler;
//   late String topic;

//   ///send to parallel bidirection event bus. You send event not trigged parallelHandler
//   void send(String topic, T data) {}

//   ///connect - this.point listen [point] and call this.handler if get a event
//   void connect(EventTreePoint point) {
//     point.runtimeType
//     connections[point] = point.streamController.stream.listen((event) {
//       event.path.add(nameNode);
//       event.count++;
//       if (ret != null) {
//         event.data = ret;

//         _upStream.add(event);
//       }
//     });
//   }

//   ///disconnect just up and down stream
//   void disconnect(
//     EventTreeNode node, {
//     bool disconnectUpStream = true,
//     bool disconnectDownStream = true,
//   }) {
//     if (disconnectUpStream) {
//       _disconnectStream(EventDirection.up, node._upStream.stream);
//     }
//     if (disconnectDownStream) {
//       _disconnectStream(EventDirection.down, node._downStream.stream);
//     }
//   }

//   bool isType<A>()
//   {
//     if(T is A)
//     {return true;}
//     return false;
//   } 
// }
