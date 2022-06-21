abstract class IEventTreeDTO {
  String get source;
  List<String> get path;
  int get count;
  dynamic get data;
  String get from;
}

class EventTreeDTO implements IEventTreeDTO {
  @override
  final String source;
  @override
  final List<String> path = [];
  @override
  dynamic data;
  @override
  int count = 0;
  @override
  String get from => path.last;
  EventTreeDTO(this.source, this.data) {
    path.add(source);
  }
}
