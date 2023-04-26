import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> getDatabase() async {
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
  });

  return db;
}

class DoughRepository {
  final Future<Database> _db;
  const DoughRepository({required db}) : _db = db;

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

  Future<void> addDough(Dough dough) async {
    final mappedDough = dough.toMap();
    mappedDough.remove("id");
    (await _db).insert("dough", mappedDough);
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
