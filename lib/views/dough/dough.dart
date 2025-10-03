import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/icons/icons.dart';
import 'package:sourbuddy/main.dart';
import 'package:sourbuddy/shared.dart';

class DoughDetails extends StatefulWidget {
  final int doughId;

  const DoughDetails({super.key, required this.doughId});

  @override
  State<DoughDetails> createState() => _DoughDetailsState();
}

class _DoughDetailsState extends State<DoughDetails> {
  LoadingState eventsLoadingState = LoadingState.notLoaded;

  @override
  Widget build(BuildContext context) {
    AppState appState = context.read<AppState>();

    if (eventsLoadingState == LoadingState.notLoaded) {
      eventsLoadingState = LoadingState.loading;
      appState.loadDoughEvents(widget.doughId);
      eventsLoadingState = LoadingState.loaded;
    }

    var dough = context.select((AppState state) => state.doughs[widget.doughId]);
    if (dough == null) {
      return Container();
    }
    var doughEvents = context.select((AppState state) => state.doughEvents[widget.doughId]);

    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 32,
              width: 32,
              child: SourdoughIcon(size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dough.name,
                  style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(dough.type),
                const SizedBox(
                  height: 4,
                ),
                Row(children: [
                  Text(
                    "Gewicht: ${dough.weight}g",
                    style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor),
                  ),
                  const Spacer(),
                  Text(
                    "Zuletzt gefüttert: ${printDuration(dough.lastFed.difference(DateTime.now()))}",
                    style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor),
                  )
                ]),
              ],
            ))
          ],
        ),
      ),
      Expanded(
          child: ListView(
              children: (doughEvents ?? []).map((event) {
        return PaddedCard(
            margin: const EdgeInsets.only(left: 16, bottom: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16, right: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        event.timestamp.toString(),
                        style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor),
                      ),
                      Text(
                        event.type.friendlyName,
                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.1),
                      ),
                      if (event.type == DoughEventType.feeding)
                        Text(
                          'Ziehzeit: ${(event.payload as Feeding).duration.inHours}h',
                        ),
                      Text(
                        'Gewicht: ${event.weightModifier.isNegative ? '' : '+'}${event.weightModifier}g',
                      )
                    ]),
                  ),
                  if (event.type != DoughEventType.created)
                    PopupMenuButton(
                        onSelected: (value) {
                          debugPrint("onSelected");
                          if (value == 0) {
                            showDialog<String>(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                      title: const Text('Teig löschen?'),
                                      content: Text('Möchtest du das Teigevent ${event.id} wirklich löschen?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'Cancel'),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, 'OK'),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    )).then((result) {
                              if ((result ?? "") == "OK") {
                                if (context.mounted) {
                                  context.read<AppState>().deleteDoughEvent(dough, event);
                                }
                              }
                            });
                          }
                        },
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (context) {
                          return <PopupMenuEntry<int>>[
                            PopupMenuItem(value: 0, child: Row(children: [Icon(Icons.delete), const Text("Löschen")]))
                          ];
                        }),
                ]));
      }).toList()))
    ]);
  }
}

class DoughDetailsPage extends StatelessWidget {
  final int doughId;

  const DoughDetailsPage({super.key, required this.doughId});

  @override
  Widget build(BuildContext context) {
    var dough = context.select((AppState state) => state.doughs[doughId]);
    if (dough == null) {
      return const Scaffold();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(dough.name),
          actions: [
            PopupMenuButton(onSelected: (value) {
              if (value == 0) {
                showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                          title: const Text('Teig löschen?'),
                          content:
                              Text('Möchtest du den Teig "${dough.name}" und die zugehörigen Events wirklich löschen?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'OK'),
                              child: const Text('OK'),
                            ),
                          ],
                        )).then((result) {
                  if ((result ?? "") == "OK" && context.mounted) {
                    Navigator.of(context).pop();
                    context.read<AppState>().deleteDough(dough);
                  }
                });
              }
            }, itemBuilder: (context) {
              return [
                PopupMenuItem<int>(value: 0, child: Row(children: [Icon(Icons.delete), const Text("Löschen")]))
              ];
            })
          ],
        ),
        body: DoughDetails(doughId: doughId),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => CreateDoughEventPage(doughId: dough.id)));
            },
            child: const Icon(Icons.add)));
  }
}

class CreateDoughEvent extends StatefulWidget {
  final int doughId;

  const CreateDoughEvent({super.key, required this.doughId});

  @override
  State<CreateDoughEvent> createState() => _CreateDoughEventState();
}

Future<DateTime?> pickDateTime(BuildContext context, {DateTime? current}) async {
  final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastDate: DateTime.parse("2099-12-31"));
  if (date == null) {
    return null;
  }
  if (context.mounted) {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()));
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute, 0);
  }
  return null;
}

class _CreateDoughEventState extends State<CreateDoughEvent> {
  final TextEditingController _doughRemovedC = TextEditingController(text: "0.0 g");
  final TextEditingController _weightExistingDoughC = TextEditingController(text: "0.0 g");
  final TextEditingController _weightFlourC = TextEditingController(text: "0.0 g");
  final TextEditingController _weightWaterC = TextEditingController(text: "0.0 g");
  final TextEditingController _riseTimeInHoursC = TextEditingController(text: "12 h");
  final TextEditingController _timerInDaysC = TextEditingController(text: "7");

  @override
  Widget build(BuildContext context) {
    final formData = context.watch<CreateDoughEventFormData>();
    final dough = context.select((AppState state) => state.doughs[widget.doughId]);

    var feedingNewWeight = 0.0;
    if (formData.doughEventType == DoughEventType.feeding) {
      feedingNewWeight = formData.weightExistingDough + formData.weightFlour + formData.weightWater;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Date: ${formData.timestamp ?? 'now'}"),
            IconButton(
                onPressed: () {
                  pickDateTime(context).then((datetime) {
                    formData.timestamp = datetime;
                  });
                },
                icon: Icon(Icons.calendar_month))
          ]),
          DropdownButtonFormField(
            initialValue: context.watch<CreateDoughEventFormData>().doughEventType,
            decoration: const InputDecoration(labelText: 'Eventtyp'),
            isExpanded: true,
            onChanged: (eventType) {
              context.read<CreateDoughEventFormData>().doughEventType = eventType!;
            },
            items: const [
              DropdownMenuItem(value: DoughEventType.feeding, child: Text('Teig füttern')),
              DropdownMenuItem(value: DoughEventType.removed, child: Text('Teil des Teiges entfernen')),
            ],
          ),
          const SizedBox(height: 16),
          if (formData.doughEventType == DoughEventType.removed) ...[
            TextFormField(
              textAlign: TextAlign.center,
              controller: _doughRemovedC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: 'Gewicht entfernt'),
              onChanged: (value) {
                double newWeight;
                try {
                  newWeight = double.parse(value);
                } catch (e) {
                  newWeight = 0.0;
                }
                debugPrint("$value, $newWeight");
                context.read<CreateDoughEventFormData>().removedWeight = newWeight;
                _doughRemovedC.value = _doughRemovedC.value.copyWith(
                  text: "$newWeight g",
                );
              },
            ),
            const SizedBox(height: 16),
            Text("Aktuelles Gewicht: ${dough?.weight} g"),
            Text("Neues Gewicht: ${(dough?.weight ?? 0) - formData.removedWeight} g"),
          ],
          if (formData.doughEventType == DoughEventType.feeding) ...[
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightExistingDoughC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: 'Teil des bisherigen Teiges'),
              onChanged: (value) {
                double weightExistingDough;
                try {
                  weightExistingDough = double.parse(value);
                } catch (e) {
                  weightExistingDough = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightExistingDough = weightExistingDough;
                _weightExistingDoughC.value = _weightExistingDoughC.value.copyWith(
                  text: "$weightExistingDough g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightFlourC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: 'Mehl'),
              onChanged: (value) {
                double weighFlour;
                try {
                  weighFlour = double.parse(value);
                } catch (e) {
                  weighFlour = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightFlour = weighFlour;
                _weightFlourC.value = _weightFlourC.value.copyWith(
                  text: "$weighFlour g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightWaterC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              decoration: const InputDecoration(labelText: 'Wasser'),
              onChanged: (value) {
                double weightWater;
                try {
                  weightWater = double.parse(value);
                } catch (e) {
                  weightWater = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightWater = weightWater;
                _weightWaterC.value = _weightWaterC.value.copyWith(
                  text: "$weightWater g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _riseTimeInHoursC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
              decoration: const InputDecoration(labelText: 'Ziehzeit'),
              onChanged: (value) {
                // if the old value is just 0, remove the last zero, so zeros can be overwritten
                var number = int.tryParse(value) ?? 0;
                if (formData.riseTimeInHours == 0) {
                  number = number ~/ 10;
                }
                formData.riseTimeInHours = number;
                _riseTimeInHoursC.value = _riseTimeInHoursC.value.copyWith(
                  text: "${formData.riseTimeInHours} h",
                );
              },
            ),
            const SizedBox(height: 16),
            Text("Übrig vom bisherigen Teig: ${(dough?.weight ?? 0.0) - formData.weightExistingDough} g"),
            Text("Neues Gewicht: $feedingNewWeight g"),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                    value: formData.createTimer,
                    onChanged: (value) {
                      formData.createTimer = value ?? false;
                    }),
                const Text('Erinnere mich in '),
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: _timerInDaysC,
                    onChanged: (value) {
                      final v = int.tryParse(value) ?? 0;
                      formData.timerInDays = v;
                      _timerInDaysC.value = _timerInDaysC.value.copyWith(text: "$v");
                    },
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true, // Added this
                    ),
                  ),
                ),
                const Text('Tagen den Teig zu füttern')
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class CreateDoughEventFormData extends ChangeNotifier {
  DateTime? _timestamp;

  DateTime? get timestamp => _timestamp;

  set timestamp(DateTime? value) {
    _timestamp = value;
    notifyListeners();
  }

  DoughEventType _doughEventType = DoughEventType.removed;

  DoughEventType get doughEventType => _doughEventType;

  set doughEventType(DoughEventType value) {
    _doughEventType = value;
    notifyListeners();
  }

  double _removedWeight = 0;

  double get removedWeight => _removedWeight;

  set removedWeight(double value) {
    _removedWeight = value;
    notifyListeners();
  }

  double _weightExistingDough = 0;

  double get weightExistingDough => _weightExistingDough;

  set weightExistingDough(double value) {
    _weightExistingDough = value;
    notifyListeners();
  }

  double _weightFlour = 0;

  double get weightFlour => _weightFlour;

  set weightFlour(double value) {
    _weightFlour = value;
    notifyListeners();
  }

  double _weightWater = 0;

  double get weightWater => _weightWater;

  set weightWater(double value) {
    _weightWater = value;
    notifyListeners();
  }

  bool _createTimer = true;

  bool get createTimer => _createTimer;

  set createTimer(bool value) {
    _createTimer = value;
    notifyListeners();
  }

  int _timerInDays = 7;

  int get timerInDays => _timerInDays;

  set timerInDays(int value) {
    _timerInDays = value;
    notifyListeners();
  }

  int _riseTimeInHours = 12;

  int get riseTimeInHours => _riseTimeInHours;

  set riseTimeInHours(int value) {
    _riseTimeInHours = value;
    notifyListeners();
  }
}

class CreateDoughEventPage extends StatelessWidget {
  final int doughId;

  const CreateDoughEventPage({super.key, required this.doughId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return CreateDoughEventFormData();
      },
      builder: (ctx, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Create Event'),
            actions: [
              TextButton(
                  onPressed: () {
                    final appState = ctx.read<AppState>();
                    final dough = appState.doughs[doughId]!;
                    final formData = ctx.read<CreateDoughEventFormData>();
                    final eventType = formData.doughEventType;
                    if (eventType == DoughEventType.removed) {
                      final removedWeight = formData.removedWeight;
                      appState
                          .addDoughEvent(
                              dough,
                              DoughEvent<Removed>(
                                  type: DoughEventType.removed,
                                  timestamp: formData.timestamp ?? DateTime.now(),
                                  payload: Removed(),
                                  weightModifier: -removedWeight))
                          .then((_) {
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      });
                    } else if (eventType == DoughEventType.feeding) {
                      final weightModifier = -(dough.weight -
                          (formData.weightExistingDough + formData.weightFlour + formData.weightWater));
                      appState
                          .addDoughEvent(
                              dough,
                              DoughEvent<Feeding>(
                                  type: DoughEventType.feeding,
                                  timestamp: formData.timestamp ?? DateTime.now(),
                                  payload: Feeding(duration: Duration(hours: formData.riseTimeInHours)),
                                  weightModifier: weightModifier))
                          .then((_) {
                        return appState.addTimer(Timer(
                            id: -1,
                            type: TimerType.finishFeeding,
                            timestamp:
                                (formData.timestamp ?? DateTime.now()).add(Duration(hours: formData.riseTimeInHours)),
                            created: (formData.timestamp ?? DateTime.now()),
                            doughId: dough.id,
                            eventId: -1));
                      }).then((_) {
                        if (formData.createTimer) {
                          return appState.addTimer(Timer(
                              id: -1,
                              type: TimerType.nextFeeding,
                              timestamp:
                                  (formData.timestamp ?? DateTime.now()).add(Duration(days: formData.timerInDays)),
                              created: (formData.timestamp ?? DateTime.now()),
                              doughId: dough.id,
                              eventId: -1));
                        }
                      }).then((_) {
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      });
                    }
                  },
                  child: const Text('Create'))
            ],
          ),
          body: CreateDoughEvent(doughId: doughId),
        );
      },
    );
  }
}

class CreateDoughPage extends StatelessWidget {
  const CreateDoughPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final appState = context.read<AppState>();
        return CreateDoughFormData(appState: appState);
      },
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Neuer Teig'),
            actions: [
              TextButton(
                  onPressed: () {
                    context.read<CreateDoughFormData>().addDough();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Create'))
            ],
          ),
          body: const CreateDoughForm(),
        );
      },
    );
  }
}

class CreateDoughFormData extends ChangeNotifier {
  AppState appState;

  CreateDoughFormData({required this.appState});

  void addDough() {
    appState.addDough(Dough(id: -1, name: name, type: type, weight: 0, lastFed: _ownedTimestamp), weight);
  }

  String _name = "";

  String get name => _name;

  set name(String name) {
    _name = name;
    notifyListeners();
  }

  String _type = "";

  String get type => _type;

  set type(String type) {
    _type = type;
    notifyListeners();
  }

  DateTime _ownedTimestamp = DateTime.now();

  DateTime get ownedTimestamp => _ownedTimestamp;

  set ownedTimestamp(DateTime ownedTimestamp) {
    _ownedTimestamp = ownedTimestamp;
    notifyListeners();
  }

  double _weight = 0.0;

  double get weight => _weight;

  set weight(double weight) {
    _weight = weight;
    notifyListeners();
  }

  bool _createTimer = true;

  bool get createTimer => _createTimer;

  set createTimer(bool v) {
    _createTimer = v;
    notifyListeners();
  }

  DateTime _nextFeedTimestamp = DateTime.now().add(const Duration(days: 7));

  DateTime get nextFeedTimestamp => _nextFeedTimestamp;

  set nextFeedTimestamp(DateTime v) {
    _nextFeedTimestamp = v;
    notifyListeners();
  }
}

class CreateDoughForm extends StatefulWidget {
  const CreateDoughForm({super.key});

  @override
  State<CreateDoughForm> createState() => _CreateDoughFormState();
}

class _CreateDoughFormState extends State<CreateDoughForm> {
  final _weightC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final weight = context.read<CreateDoughFormData>().weight;
    _weightC.value = _weightC.value.copyWith(text: "$weight g");
  }

  @override
  Widget build(BuildContext context) {
    final formData = context.watch<CreateDoughFormData>();
    return Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Name des Teiges',
              ),
              onChanged: (v) {
                formData.name = v;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Mehlart',
              ),
              onChanged: (v) {
                formData.type = v;
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Du hast deinen Sauerteig seit: ${formData.ownedTimestamp}"),
                IconButton(
                    onPressed: () {
                      pickDateTime(context, current: formData.ownedTimestamp).then((datetime) {
                        formData.ownedTimestamp = datetime ?? DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.calendar_month))
              ],
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Aktuelles Gewicht'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              controller: _weightC,
              onChanged: (v) {
                double newWeight = 0.0;
                try {
                  newWeight = double.parse(v);
                } catch (_) {
                  newWeight = 0;
                }
                debugPrint("$v, $newWeight");
                formData.weight = newWeight;
                _weightC.value = _weightC.value.copyWith(
                  text: "$newWeight g",
                );
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Checkbox(
                    value: formData.createTimer,
                    onChanged: (v) {
                      formData.createTimer = v ?? false;
                    }),
                Expanded(child: Text("Erinnere mich am ${formData.nextFeedTimestamp} den Teig zu füttern")),
                IconButton(
                    onPressed: () {
                      pickDateTime(context, current: formData.nextFeedTimestamp).then((datetime) {
                        formData.nextFeedTimestamp = datetime ?? DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.calendar_month))
              ],
            ),
          ],
        ));
  }
}
