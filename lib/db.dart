import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseConnection {
  Future<Database>? db;

  Future<Database> get() async {
    if (db != null) {
      return db!;
    }
    return _init();
  }

  Future<Database> _init() async {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      db = databaseFactoryFfi.openDatabase("./dough.sqlite");
    } else {
      final path = "${await getDatabasesPath()}/dough.sqlite";
      debugPrint("path $path");
      db = databaseFactory.openDatabase(path);
    }

    return db!.then((db) async {
      await db.execute('''
CREATE TABLE IF NOT EXISTS dough (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  weight REAL NOT NULL,
  last_fed TEXT NOT NULL
)
''');
      await db.execute('''
CREATE TABLE IF NOT EXISTS event (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  dough_id INTEGER NOT NULL,
  type TEXT NOT NULL,               -- event type
  timestamp TEXT NOT NULL,
  weight_modifier REAL NOT NULL,    -- for easy calculations, we just store the difference in the weight
  json_payload TEXT NOT NULL,       -- additional JSON data
  FOREIGN KEY(dough_id) REFERENCES dough(id)
)
''');
      debugPrint('table pls?');
      await db.execute('''
CREATE TABLE IF NOT EXISTS timer (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,                           -- timer type
  timestamp TEXT NOT NULL,                      -- when the timer should ring
  created TEXT NOT NULL,                        -- when the timer was created 
  dough_id INTEGER,
  event_id INTEGER,
  FOREIGN KEY(dough_id) REFERENCES dough(id),
  FOREIGN KEY(event_id) REFERENCES event(id)
)
''');

      return db;
    });
  }
}

class DoughRepository {
  final DatabaseConnection _db;

  const DoughRepository({required DatabaseConnection db}) : _db = db;

  Future<Iterable<Dough>> listDoughs() async {
    var doughs = await (await _db.get()).query('dough');
    return doughs.map((doughMap) {
      debugPrint(doughMap.toString());
      return Dough.fromMap(doughMap);
    });
  }

  Future<Iterable<DoughEvent>> listEvents(int doughId) async {
    var events = await (await _db.get())
        .query('event', where: '"dough_id" = ?', whereArgs: [doughId], orderBy: 'timestamp desc');
    return events.map((eventMap) {
      var eventType = DoughEventType.from(
        eventMap['type'] as String,
      );
      DoughEventPayload payload;
      if (eventType == DoughEventType.feeding) {
        payload = Feeding.fromJson(jsonDecode(eventMap['json_payload'] as String));
      } else if (eventType == DoughEventType.created) {
        payload = Created.fromJson(jsonDecode(eventMap['json_payload'] as String));
      } else if (eventType == DoughEventType.removed) {
        payload = Created.fromJson(jsonDecode(eventMap['json_payload'] as String));
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

  Future<int> addEvent(Dough dough, DoughEvent event) async {
    return (await _db.get()).transaction((txn) async {
      final eventMap = event.toMap(dough.id);
      eventMap.remove("id");
      final eventId = await txn.insert('event', eventMap);

      final oldDough = Dough.fromMap((await txn.query('dough', where: "id = ?", whereArgs: [dough.id])).first);
      final Map<String, dynamic> values = {'weight': oldDough.weight + event.weightModifier};
      if (event.type == DoughEventType.feeding) {
        values['last_fed'] = event.timestamp.toIso8601String();
      }
      await txn.update(
        'dough',
        values,
        where: "id = ?",
        whereArgs: [dough.id],
      );

      return eventId;
    });
  }

  Future<int> addDough(Dough dough) async {
    final mappedDough = dough.toMap();
    mappedDough.remove("id");
    return await (await _db.get()).insert("dough", mappedDough);
  }

  Future<void> deleteDough(Dough dough) async {
    await (await _db.get()).delete("dough", where: "id = ?", whereArgs: [dough.id]);
  }

  Future<void> deleteEvent(Dough dough, DoughEvent event) async {
    (await _db.get()).transaction((txn) async {
      await txn.delete("event", where: "id = ?", whereArgs: [event.id]);

      final oldDough = Dough.fromMap((await txn.query('dough', where: "id = ?", whereArgs: [dough.id])).first);
      final Map<String, dynamic> values = {'weight': oldDough.weight - event.weightModifier};
      // FIXME: in case a feeding event is deleted, search for last last_fed timestamp and apply it's date
      txn.update(
        'dough',
        values,
        where: "id = ?",
        whereArgs: [dough.id],
      );
    });
  }
}

class TimerRepository {
  final DatabaseConnection _db;

  const TimerRepository({required DatabaseConnection db}) : _db = db;

  Future<List<Timer>> listTimers() async {
    var timers = await (await _db.get()).query('timer');
    return timers.map((timerMap) {
      return Timer.fromMap(timerMap);
    }).toList();
  }

  Future<int> addTimer(Timer timer) async {
    final map = timer.toMap();
    map.remove("id");
    return await (await _db.get()).insert("timer", map);
  }

  Future<void> deleteTimer(Timer timer) async {
    await (await _db.get()).delete("timer", where: "id = ?", whereArgs: [timer.id]);
  }
}

// Models
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

  Map<String, Object?> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "weight": weight,
      "last_fed": lastFed.toIso8601String(),
    };
  }

  Dough copyWith({double? weight}) {
    return Dough(id: id, name: name, type: type, weight: weight ?? this.weight, lastFed: lastFed);
  }
}

class DoughEvent<T extends DoughEventPayload> {
  final int? id;
  final DoughEventType type;
  final DateTime timestamp;
  final double weightModifier;
  final T payload;

  DoughEvent(
      {this.id, required this.type, required this.timestamp, required this.weightModifier, required this.payload});

  Map<String, Object?> toMap(int doughId) {
    return {
      "id": this.id,
      "dough_id": doughId,
      "type": this.type.name,
      "timestamp": this.timestamp.toIso8601String(),
      "weight_modifier": this.weightModifier,
      "json_payload": jsonEncode(this.payload.toJson()),
    };
  }
}

abstract class DoughEventPayload {
  Map<String, dynamic> toJson();
}

class Feeding extends DoughEventPayload {
  final Duration duration;

  Feeding({required this.duration});

  Feeding.fromJson(Map<String, dynamic> json) : duration = Duration(seconds: json['duration'] ?? 0);

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

class Timer {
  int id;
  TimerType type;
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
        type = TimerType.from(map["type"] as String),
        timestamp = DateTime.parse(map["timestamp"] as String),
        created = DateTime.parse(map["created"] as String),
        doughId = map["dough_id"] as int?,
        eventId = map["event_id"] as int?;

  Map<String, Object?> toMap() {
    return {
      "id": id,
      "type": type.name,
      "timestamp": timestamp.toIso8601String(),
      "created": created.toIso8601String(),
      "dough_id": doughId,
      "event_id": eventId,
    };
  }
}

enum TimerType {
  finishFeeding(friendlyName: "Teigfütterung abgeschlossen"),
  nextFeeding(friendlyName: "Nächste Teigfütterung");

  const TimerType({required this.friendlyName});

  final String friendlyName;

  static TimerType from(String type) {
    switch (type) {
      case "finishFeeding":
        return TimerType.finishFeeding;
      case "nextFeeding":
        return TimerType.nextFeeding;
      default:
        throw Exception(type);
    }
  }
}
