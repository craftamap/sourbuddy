import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/dough.dart';
import 'package:sourbuddy/shared.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Future<Database>? db;
  if (defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    db = databaseFactoryFfi.openDatabase("./dough.sqlite");
  } else {
    final path = "${await getDatabasesPath()}/dough.sqlite";
    debugPrint(path);
    db = databaseFactory.openDatabase(path);
  }
  db.then((db) async {
    db.execute('''
CREATE TABLE IF NOT EXISTS dough (
  id INTEGER PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  weight REAL NOT NULL,
  last_fed TEXT NOT NULL
)
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS event (
  id INTEGER PRIMARY KEY NOT NULL,
  dough_id INTEGER NOT NULL,
  type TEXT NOT NULL,               -- event type
  timestamp TEXT NOT NULL,
  weight_modifier REAL NOT NULL,    -- for easy calculations, we just store the difference in the weight
  json_payload TEXT NOT NULL,       -- additional JSON data
  FOREIGN KEY(dough_id) REFERENCES dough(id)
)
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS timer (
  id INTEGER PRIMARY KEY NOT NULL,
  type TEXT NOT NULL,                           -- timer type
  timestamp TEXT NOT NULL,                      -- when the timer should ring
  created TEXT NOT NULL,                        -- when the timer was created 
  dough_id INTEGER,
  event_id INTEGER,
  FOREIGN KEY(dough_id) REFERENCES dough(id),
  FOREIGN KEY(event_id) REFERENCES event(id)
)
''');
    if (defaultTargetPlatform == TargetPlatform.android) {
      db.execute(
          '''INSERT INTO "dough" VALUES (1,'Feuchte Mirjam','Roggenmehl',40.0,'2023-04-16T12:03:47.679300')''');
      db.execute(
          '''INSERT INTO "event" VALUES (1,1,'created','2022-12-24',120.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (2,1,'feeding','2023-04-09T20:45:32+0000',0.0,'{"duration": 43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (3,1,'feeding','2023-04-10T00:00:00Z',-10.0,'{"duration": 10}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (4,1,'removed','2023-04-11T20:20:20Z',-20.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (5,1,'removed','2023-04-13T21:59:41.514746',-42.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (6,1,'removed','2023-04-13T22:02:01.907061',-42.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (7,1,'removed','2023-04-13T22:40:10.772148',-20.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (8,1,'removed','2023-04-13T22:49:51.244408',-30.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (9,1,'removed','2023-04-13T22:50:17.785345',-20.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (10,1,'removed','2023-04-13T22:50:34.976882',-100.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (11,1,'removed','2023-04-13T22:59:56.124684',-200.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (12,1,'removed','2023-04-15T14:31:07.177018',0.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (13,1,'removed','2023-04-16T11:06:22.618330',0.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (14,1,'removed','2023-04-16T11:08:07.483234',0.0,'{}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (15,1,'feeding','2023-04-16T11:23:31.478588',0.0,'{"duration":43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (16,1,'feeding','2023-04-16T11:26:41.590265',0.0,'{"duration":43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (17,1,'feeding','2023-04-16T11:26:57.780740',20.0,'{"duration":43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (18,1,'feeding','2023-04-16T11:32:43.845470',-60.0,'{"duration":43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (19,1,'feeding','2023-04-16T12:03:47.679300',60.0,'{"duration":43200}')''');
      db.execute(
          '''INSERT INTO "event" VALUES (20,1,'removed','2023-04-16T12:04:04.674326',-20.0,'{}')''');
      db.execute(
          '''INSERT INTO "timer" VALUES (1,'feeding','2023-04-21T12:00:00Z','2023-04-18T22:52:00Z',NULL,NULL)''');
    }
  });

  runApp(ChangeNotifierProvider(
    create: (ctx) => AppState(
        doughService: DoughService(db: db), timerService: TimerService(db: db)),
    child: const MyApp(),
  ));
}

class DoughService {
  final Future<Database> _db;
  const DoughService({required db}) : _db = db;

  Future<Iterable<Dough>> listDoughs() async {
    var doughs = await (await _db).query('dough');
    return doughs.map((doughMap) {
      debugPrint(doughMap.toString());
      return Dough.fromMap(doughMap);
    });
  }

  Future<Iterable<DoughEvent>> listEvents(int doughId) async {
    var events = await (await _db).query('event',
        where: '"dough_id" = ?',
        whereArgs: [doughId],
        orderBy: 'timestamp desc');
    return events.map((eventMap) {
      var eventType = DoughEventType.from(
        eventMap['type'] as String,
      );
      DoughEventPayload payload;
      if (eventType == DoughEventType.feeding) {
        payload =
            Feeding.fromJson(jsonDecode(eventMap['json_payload'] as String));
      } else if (eventType == DoughEventType.created) {
        payload =
            Created.fromJson(jsonDecode(eventMap['json_payload'] as String));
      } else if (eventType == DoughEventType.removed) {
        payload =
            Created.fromJson(jsonDecode(eventMap['json_payload'] as String));
      } else {
        throw 'unknown!';
      }

      return DoughEvent(
        id: eventMap['id'] as int,
        type: eventType,
        timestamp: DateTime.parse(eventMap['timestamp'] as String),
        weightModifier: eventMap['weight_modifier'] as double,
        payload: payload,
      );
    });
  }

  Future<void> addEvent(Dough dough, DoughEvent event) async {
    (await _db).transaction((txn) async {
      txn.insert('event', {
        "id": event.id,
        "dough_id": dough.id,
        "type": event.type.name,
        "timestamp": event.timestamp.toIso8601String(),
        "weight_modifier": event.weightModifier,
        "json_payload": jsonEncode(event.payload.toJson()),
      });

      final oldDough = Dough.fromMap(
          (await txn.query('dough', where: "id = ?", whereArgs: [dough.id]))
              .first);
      final Map<String, dynamic> values = {
        'weight': oldDough.weight + event.weightModifier
      };
      if (event.type == DoughEventType.feeding) {
        values['last_fed'] = event.timestamp.toIso8601String();
      }
      txn.update(
        'dough',
        values,
        where: "id = ?",
        whereArgs: [dough.id],
      );
    });
  }
}

class TimerService {
  final Future<Database> _db;
  const TimerService({required db}) : _db = db;

  Future<List<Timer>> listTimers() async {
    var timers = await (await _db).query('timer');
    return timers.map((timerMap) {
      return Timer.fromMap(timerMap);
    }).toList();
  }
}

class AppState extends ChangeNotifier {
  bool loading = true;
  Map<int, Dough> doughs = {};
  Map<int, List<DoughEvent>> doughEvents = {};
  Map<int, Timer> timers = {};
  final DoughService _doughService;
  final TimerService _timerService;

  AppState({required doughService, required timerService})
      : _doughService = doughService,
        _timerService = timerService {
    init();
  }

  init() async {
    loadDoughs();
    loadTimers();
  }

  loadDoughs() async {
    var doughs = await _doughService.listDoughs();
    this.doughs.clear();
    for (Dough dough in doughs) {
      this.doughs[dough.id] = dough;
    }
    loading = false;
    notifyListeners();
  }

  loadDoughEvents(int doughId) async {
    doughEvents[doughId] = (await _doughService.listEvents(doughId)).toList();
    notifyListeners();
  }

  Future<void> addDoughEvent(Dough dough, DoughEvent event) async {
    await _doughService.addEvent(dough, event);
    // Invalidate dough and it's events
    loadDoughs();
    loadDoughEvents(dough.id);
  }

  loadTimers() async {
    final timers = await _timerService.listTimers();
    this.timers.clear();
    for (Timer timer in timers) {
      this.timers[timer.id] = timer;
    }
    notifyListeners();
  }
}

class Dough {
  final int id;
  final String name;
  final String type;
  final double weight;
  final DateTime lastFed;

  Dough({
    required this.id,
    required this.name,
    required this.type,
    required this.weight,
    required this.lastFed,
  });

  Dough.fromMap(Map<String, Object?> map)
      : id = map['id'] as int,
        name = map['name'] as String,
        type = map['type'] as String,
        weight = map['weight'] as double,
        lastFed = DateTime.parse(map['last_fed'] as String);
}

class DoughEvent<T extends DoughEventPayload> {
  final int? id;
  final DoughEventType type;
  final DateTime timestamp;
  final double weightModifier;
  final T payload;

  DoughEvent(
      {this.id,
      required this.type,
      required this.timestamp,
      required this.weightModifier,
      required this.payload});
}

abstract class DoughEventPayload {
  Map<String, dynamic> toJson();
}

class Feeding extends DoughEventPayload {
  final Duration duration;
  Feeding({required this.duration});

  Feeding.fromJson(Map<String, dynamic> json)
      : duration = Duration(seconds: json['duration'] ?? 0);

  @override
  Map<String, dynamic> toJson() {
    return {
      "duration": duration.inSeconds,
    };
  }
}

class Created extends DoughEventPayload {
  Created();

  Created.fromJson(Map<String, dynamic> json);

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}

class Removed extends DoughEventPayload {
  Removed();

  Removed.fromJson(Map<String, dynamic> json);

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}

enum DoughEventType {
  feeding(friendlyName: 'Teig gefüttert'),
  removed(friendlyName: 'Teil des Teiges entnommen'),
  created(friendlyName: 'Neuer Teig');

  const DoughEventType({required this.friendlyName});

  final String friendlyName;
  static DoughEventType from(String name) {
    switch (name) {
      case 'feeding':
        return DoughEventType.feeding;
      case 'removed':
        return DoughEventType.removed;
      case 'created':
        return DoughEventType.created;
      default:
        throw 'unknown DoughEventType';
    }
  }
}

enum LoadingState {
  notLoaded,
  loading,
  loaded,
}

class Timer {
  int id;
  DoughEventType type;
  DateTime timestamp;
  DateTime created;
  int? doughId;
  int? eventId;
  Timer(
      {required this.id,
      required this.type,
      required this.timestamp,
      required this.created,
      required this.doughId,
      required this.eventId});

  Timer.fromMap(Map<String, Object?> map)
      : id = map["id"] as int,
        type = DoughEventType.from(map["type"] as String),
        timestamp = DateTime.parse(map["timestamp"] as String),
        created = DateTime.parse(map["created"] as String),
        doughId = map["dough_id"] as int?,
        eventId = map["event_id"] as int?;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SourBuddy',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.brown,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navigationIndex = 0;
  final List<Widget> _pages = <Widget>[
    const Center(
      child: DoughsOverview(),
    ),
    const Center(
      child: TimerOverview(),
    ),
  ];

  void _onNavigationItemTapped(int index) {
    setState(() {
      _navigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SourBuddy')),
      body: _pages.elementAt(_navigationIndex),
      bottomNavigationBar:
          BottomNavigationBar(items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.science), label: "Doughs"),
        BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timers"),
      ], currentIndex: _navigationIndex, onTap: _onNavigationItemTapped),
    );
  }
}

class TimerOverview extends StatefulWidget {
  const TimerOverview({super.key});

  @override
  State<TimerOverview> createState() => _TimerOverviewState();
}

class _TimerOverviewState extends State<TimerOverview> {
  @override
  void initState() {
    var reload;
    reload = () {
      setState(() {});
      Future.delayed(Duration(seconds: 2), reload);
    };
    reload();
  }

  @override
  Widget build(BuildContext context) {
    List<Timer> timers =
        context.select((AppState state) => state.timers).values.toList();

    return Column(
      children: timers.map((timer) {
        return PaddedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Noch"),
              Text(
                "${printDuration(timer.timestamp.difference(DateTime.now()))}",
                style:
                    DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2),
              ),
              Text("bis ${timer.type.friendlyName}")
            ],
          ),
        );
      }).toList(),
    );
  }
}
