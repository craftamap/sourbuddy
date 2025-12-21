import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/main.dart';
import 'package:sourbuddy/shared.dart';


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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
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
                          ),
                        );
                        // TODO: create timers - consider using a service layer for everything!
                        Navigator.pop(context);
                      },
                      child: Text('Erstellen'),
                    ),
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
                        },
                      ),
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
                        },
                      ),
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
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text("Neues Gewicht: ${newWeight} g")]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text("Übrig vom bisherigen Teig: ${remainingWeight} g")],
                ),
                Divider(),
                Row(
                  children: [
                    Expanded(child: Text("Wann?", style: bodyLarge)),
                    Text(
                      this.timestamp != null ? DateFormat.yMd().add_Hm().format(this.timestamp!) : "Jetzt",
                      style: bodyLarge,
                    ),
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
                      icon: Icon(Icons.calendar_month),
                    ),
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
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text("Nächste Fütterung", style: bodyLarge)),
                    Text(
                      this.timestampNext != null ? DateFormat.yMd().add_Hm().format(this.timestampNext!) : "7 Tage",
                      style: bodyLarge,
                    ),
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
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateFeedingEventViewModel {
  final AppState appState;

  const CreateFeedingEventViewModel({required this.appState});

  void addFeedingEvent() {

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
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+([\.]\d*)?'))],
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
