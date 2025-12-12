import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/icons/icons.dart';
import 'package:sourbuddy/main.dart';
import 'package:sourbuddy/shared.dart';

import 'create_dough_event.dart';

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
                        style: DefaultTextStyle.of(context).style.apply(fontSizeDelta: 2),
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
        floatingActionButton:
            Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
          FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext ctx) {
                    return CreateFeedingEvent(doughId: doughId);
                  });
            },
            icon: const Icon(Icons.add),
            label: Text('Füttern'),
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => CreateDoughEventPage(doughId: dough.id)));
              },
              icon: const Icon(Icons.add),
              label: Text('Entfernen'))
        ]));
  }
}

class CreateFeedingEvent extends StatefulWidget {
  final int doughId;

  const CreateFeedingEvent({super.key, required this.doughId});

  @override
  State<CreateFeedingEvent> createState() => CreateFeedingEventState();
}

class CreateFeedingEventState extends State<CreateFeedingEvent> {
  static final DEFAULT_FERMENTATION_DURATION_IN_H = 12;
  final doughController = TextEditingController();
  final waterController = TextEditingController();
  final flourController = TextEditingController();

  double? doughWeight = null;
  double? waterWeight = null;
  double? flourWeight = null;
  double fermentationDurationInH = 12;
  DateTime? timestamp = null;
  DateTime? timestampNext = null;

  @override
  Widget build(BuildContext context) {
    final dough = context.select((AppState state) => state.doughs[widget.doughId]);
    final bodyLarge = DefaultTextStyle.of(context).style.apply(fontSizeDelta: 2);
    final newWeight = (doughWeight ?? 0) + (waterWeight ?? 0) + (flourWeight ?? 0);
    final remainingWeight = (dough?.weight ?? 0) - newWeight;

    final appState = context.read<AppState>();

    return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Wrap(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close)),
                    FilledButton(
                      onPressed: () {
                        final weightModifier = newWeight - (dough?.weight ?? 0);
                        appState.addDoughEvent(
                            dough!,
                            DoughEvent<Feeding>(
                              type: DoughEventType.feeding,
                              timestamp: timestamp ?? DateTime.now(),
                              weightModifier: weightModifier,
                              // todo: this should not be a float?
                              payload: Feeding(duration: Duration(hours: fermentationDurationInH.floor())),
                            ));
                        // TODO: create timers - consider using a service layer for everything!
                        Navigator.pop(context);
                      },
                      child: Text('Erstellen'),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 96,
                      child: BigNumber(
                          controller: doughController,
                          labelText: 'Sauerteig',
                          onChange: (value) {
                            setState(() {
                              this.doughWeight = value;
                            });
                          }),
                    ),
                    SizedBox(
                      width: 96,
                      child: BigNumber(
                          controller: waterController,
                          labelText: 'Wasser',
                          onChange: (value) {
                            setState(() {
                              this.waterWeight = value;
                            });
                          }),
                    ),
                    SizedBox(
                      width: 96,
                      child: BigNumber(
                          controller: flourController,
                          labelText: 'Mehl',
                          onChange: (value) {
                            setState(() {
                              this.flourWeight = value;
                            });
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text("Neues Gewicht: ${newWeight} g"),
                ]),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Text("Übrig vom bisherigen Teig: ${remainingWeight} g"),
                ]),
                Divider(),
                Row(
                  children: [
                    Expanded(child: Text("Wann?", style: bodyLarge)),
                    Text(this.timestamp != null ? DateFormat.yMd().add_Hm().format(this.timestamp!) : "Jetzt",
                        style: bodyLarge),
                    IconButton(
                        onPressed: () {
                          pickDateTime(context, current: this.timestamp).then((value) {
                            setState(() {
                              if (value != null) {
                                this.timestamp = value;
                              }
                            });
                          });
                        },
                        icon: Icon(Icons.calendar_month))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Ziehzeit", style: bodyLarge),
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: TextField(
                          textAlign: TextAlign.end,
                          onChanged: (value) {
                            setState(() {
                              this.fermentationDurationInH = double.parse(value);
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "${DEFAULT_FERMENTATION_DURATION_IN_H}",
                            suffix: Text("h"),
                            border: UnderlineInputBorder(),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Row(children: [
                  Expanded(
                    child: Text("Nächste Fütterung", style: bodyLarge),
                  ),
                  Text(this.timestampNext != null ? DateFormat.yMd().add_Hm().format(this.timestampNext!) : "7 Tage",
                      style: bodyLarge),
                  IconButton(
                      onPressed: () {
                        pickDateTime(context, current: DateTime.now().add(Duration(days: 7))).then((value) {
                          setState(() {
                            if (value != null) {
                              this.timestampNext = value;
                            }
                          });
                        });
                      },
                      icon: Icon(Icons.calendar_month)),
                ])
              ]),
            )
          ],
        ));
  }
}

class BigNumber extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(double?) onChange;

  const BigNumber({super.key, required this.controller, required this.labelText, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 24),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+([\.]\d*)?')),
      ],
      onChanged: (value) {
        double? parsedValue = double.tryParse(value);
        onChange(parsedValue);
      },
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        suffixText: 'g',
        hintText: '0',
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
