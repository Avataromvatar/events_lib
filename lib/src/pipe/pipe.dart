import 'dart:async';

typedef PipeHandler<L, R> = void Function(
  String? name, {
  L? dataL,
  Function(R data) emitL,
  R? dataR,
  Function(L data) emitR,
});

class Interceptor {}

///Pipe
///<-> stream <-> handler <-> stream <->
class Pipe<L, R> {
  String? name;
  StreamController<L> _leftStream;
  StreamController<R> _rightStream;
  List<PipeHandler<L, R>> _handlers;
}
