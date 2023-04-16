import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/main.dart';
import 'package:sourbuddy/shared.dart';

String _printDuration(Duration duration) {
  duration = duration.abs();
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitsHours = twoDigits(duration.inHours.remainder(24));
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  return "${duration.inDays}d $twoDigitsHours:$twoDigitMinutes";
}

class DoughsOverview extends StatelessWidget {
  const DoughsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoading = context.select((AppState state) => state.loading);
    if (isLoading) {
      return (const CircularProgressIndicator());
    }
    List<Dough> doughs =
        context.select((AppState state) => state.doughs).values.toList();
    debugPrint(doughs.toString());
    var children = doughs.map((dough) {
      return PaddedCard(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DoughDetailsPage(doughId: dough.id)));
        },
        child: Row(
          children: [
            const SizedBox(
              height: 32,
              width: 32,
              child: Icon(Icons.science, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dough.name,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.2),
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
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).hintColor),
                  ),
                  const Spacer(),
                  Text(
                    "Zuletzt gefüttert: ${_printDuration(dough.lastFed.difference(DateTime.now()))}",
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).hintColor),
                  )
                ]),
              ],
            ))
          ],
        ),
      );
    }).toList();
    return ListView(
      children: children,
    );
  }
}

class DoughDetails extends StatefulWidget {
  final int doughId;

  const DoughDetails({super.key, required this.doughId});

  @override
  State<DoughDetails> createState() => _DoughDetailsState();
}

class _DoughDetailsState extends State<DoughDetails> {
  LoadingState events = LoadingState.notLoaded;

  @override
  Widget build(BuildContext context) {
    if (events == LoadingState.notLoaded) {
      debugPrint('foo');
      events = LoadingState.loading;
      context.read<AppState>().loadDoughEvents(widget.doughId);
      events = LoadingState.loaded;
    }

    var dough =
        context.select((AppState state) => state.doughs[widget.doughId]!);
    var doughEvents =
        context.select((AppState state) => state.doughEvents[widget.doughId]);

    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 32,
              width: 32,
              child: Icon(Icons.science, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dough.name,
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.2),
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
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).hintColor),
                  ),
                  const Spacer(),
                  Text(
                    "Zuletzt gefüttert: ${_printDuration(dough.lastFed.difference(DateTime.now()))}",
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).hintColor),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              event.timestamp.toString(),
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: Theme.of(context).hintColor),
            ),
            Text(
              event.type.friendlyName,
              style:
                  DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.1),
            ),
            if (event.type == DoughEventType.feeding)
              Text(
                'Ziehzeit: ${(event.payload as Feeding).duration.inHours}h',
              ),
            Text(
              'Gewicht: ${event.weightModifier.isNegative ? '' : '+'}${event.weightModifier}g',
            )
          ]),
        );
      }).toList()))
    ]);
  }
}

class DoughDetailsPage extends StatelessWidget {
  final int doughId;
  const DoughDetailsPage({super.key, required this.doughId});

  @override
  Widget build(BuildContext context) {
    var dough = context.select((AppState state) => state.doughs[doughId]!);

    return Scaffold(
        appBar: AppBar(
          title: Text(dough.name),
          actions: const [],
        ),
        body: DoughDetails(doughId: doughId),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      CreateDoughEventPage(doughId: dough.id)));
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

class _CreateDoughEventState extends State<CreateDoughEvent> {
  final TextEditingController _doughRemovedC =
      TextEditingController(text: "0.0 g");
  final TextEditingController _weightExistingDoughC =
      TextEditingController(text: "0.0 g");
  final TextEditingController _weightFlourC =
      TextEditingController(text: "0.0 g");
  final TextEditingController _weightWaterC =
      TextEditingController(text: "0.0 g");
  final TextEditingController _riseTimeInHoursC =
      TextEditingController(text: "12 h");
  final TextEditingController _timerInDaysC = TextEditingController(text: "7");

  @override
  Widget build(BuildContext context) {
    final formData = context.watch<CreateDoughEventFormData>();
    final dough =
        context.select((AppState state) => state.doughs[widget.doughId]);

    var feedingNewWeight = 0.0;
    if (formData.doughEventType == DoughEventType.feeding) {
      feedingNewWeight = formData.weightExistingDough +
          formData.weightFlour +
          formData.weightWater;
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
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          lastDate: DateTime.parse("2099-12-31"))
                      .then((date) async {
                    if (date == null) {
                      return;
                    }
                    final time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time == null) {
                      return;
                    }
                    final timestamp = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute, time.hour);
                    formData.timestamp = timestamp;
                  });
                },
                icon: Icon(Icons.calendar_month))
          ]),
          DropdownButtonFormField(
            value: context.watch<CreateDoughEventFormData>().doughEventType,
            decoration: const InputDecoration(labelText: 'Eventtyp'),
            isExpanded: true,
            onChanged: (eventType) {
              context.read<CreateDoughEventFormData>().doughEventType =
                  eventType!;
            },
            items: const [
              DropdownMenuItem(
                  value: DoughEventType.feeding, child: Text('Teig füttern')),
              DropdownMenuItem(
                  value: DoughEventType.removed,
                  child: Text('Teil des Teiges entfernen')),
            ],
          ),
          const SizedBox(height: 16),
          if (formData.doughEventType == DoughEventType.removed) ...[
            TextFormField(
              textAlign: TextAlign.center,
              controller: _doughRemovedC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
              ],
              decoration: const InputDecoration(labelText: 'Gewicht entfernt'),
              onChanged: (value) {
                double newWeight;
                try {
                  newWeight = double.parse(value);
                } catch (e) {
                  newWeight = 0.0;
                }
                context.read<CreateDoughEventFormData>().removedWeight =
                    newWeight;
                _doughRemovedC.value = _doughRemovedC.value.copyWith(
                  text: "$newWeight g",
                );
              },
            ),
            const SizedBox(height: 16),
            Text("Aktuelles Gewicht: ${dough?.weight} g"),
            Text(
                "Neues Gewicht: ${(dough?.weight ?? 0) - formData.removedWeight} g"),
          ],
          if (formData.doughEventType == DoughEventType.feeding) ...[
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightExistingDoughC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
              ],
              decoration: const InputDecoration(
                  labelText: 'Teil des bisherigen Teiges'),
              onChanged: (value) {
                double weightExistingDough;
                try {
                  weightExistingDough = double.parse(value);
                } catch (e) {
                  weightExistingDough = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightExistingDough =
                    weightExistingDough;
                _weightExistingDoughC.value =
                    _weightExistingDoughC.value.copyWith(
                  text: "$weightExistingDough g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightFlourC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
              ],
              decoration: const InputDecoration(labelText: 'Mehl'),
              onChanged: (value) {
                double weighFlour;
                try {
                  weighFlour = double.parse(value);
                } catch (e) {
                  weighFlour = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightFlour =
                    weighFlour;
                _weightFlourC.value = _weightFlourC.value.copyWith(
                  text: "$weighFlour g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _weightWaterC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))
              ],
              decoration: const InputDecoration(labelText: 'Wasser'),
              onChanged: (value) {
                double weightWater;
                try {
                  weightWater = double.parse(value);
                } catch (e) {
                  weightWater = 0.0;
                }
                context.read<CreateDoughEventFormData>().weightWater =
                    weightWater;
                _weightWaterC.value = _weightWaterC.value.copyWith(
                  text: "$weightWater g",
                );
              },
            ),
            TextFormField(
              textAlign: TextAlign.center,
              controller: _riseTimeInHoursC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              ],
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
            Text(
                "Übrig vom bisherigen Teig: ${(dough?.weight ?? 0.0) - formData.weightExistingDough} g"),
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
                      _timerInDaysC.value =
                          _timerInDaysC.value.copyWith(text: "$v");
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
    final ButtonStyle style = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );

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
                  style: style,
                  onPressed: () {
                    final dough = ctx.read<AppState>().doughs[doughId]!;
                    final formData = ctx.read<CreateDoughEventFormData>();
                    final eventType = formData.doughEventType;
                    if (eventType == DoughEventType.removed) {
                      final removedWeight = formData.removedWeight;
                      ctx
                          .read<AppState>()
                          .addDoughEvent(
                              dough,
                              DoughEvent<Removed>(
                                  type: DoughEventType.removed,
                                  timestamp:
                                      formData.timestamp ?? DateTime.now(),
                                  payload: Removed(),
                                  weightModifier: -removedWeight))
                          .then((_) {
                        Navigator.of(ctx).pop();
                      });
                    } else if (eventType == DoughEventType.feeding) {
                      final weightModifier = -(dough.weight -
                          (formData.weightExistingDough +
                              formData.weightFlour +
                              formData.weightWater));
                      ctx
                          .read<AppState>()
                          .addDoughEvent(
                              dough,
                              DoughEvent<Feeding>(
                                  type: DoughEventType.feeding,
                                  timestamp:
                                      formData.timestamp ?? DateTime.now(),
                                  payload: Feeding(
                                      duration: Duration(
                                          hours: formData.riseTimeInHours)),
                                  weightModifier: weightModifier))
                          .then((_) {
                        Navigator.of(ctx).pop();
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
