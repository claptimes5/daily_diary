class Recording {
//  final String name;
//  final String message;
  final DateTime time;

//  final String avatarUrl;

//  Recording({this.name, this.message, this.time, this.avatarUrl});
  Recording({this.time});
}

List<Recording> dummyData = [
  new Recording(time: DateTime.now()),
  new Recording(time: DateTime.now()),
  new Recording(time: DateTime.now())
];
