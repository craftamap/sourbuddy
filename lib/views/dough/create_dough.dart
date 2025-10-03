import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/main.dart';

import '../../shared.dart';

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
