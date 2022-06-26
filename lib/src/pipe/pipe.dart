import 'dart:async';

///Pipe
///<-> stream <-> handler <-> stream <->
class Pipe<L, R> {
  StreamController<L> _leftStream;
  StreamController<R> _rightStream;
}
