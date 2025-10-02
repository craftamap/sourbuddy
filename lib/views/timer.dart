import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/main.dart';

import '../shared.dart';

class TimerOverview extends StatefulWidget {
  const TimerOverview({super.key});

  @override
  State<TimerOverview> createState() => _TimerOverviewState();
}

class _TimerOverviewState extends State<TimerOverview> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    List<Timer> timers = appState.timers.values.toList();
    Map<int, Dough> doughs = appState.doughs;

    return Column(
      children: timers.map((timer) {
        return PaddedCard(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (doughs[timer.doughId]?.name != null) ...[
                      Text(doughs[timer.doughId]?.name ?? 'ur mom',
                          style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor))
                    ],
                    const Text("Noch"),
                    Text(
                      printDuration(timer.timestamp.difference(DateTime.now()), absolute: false),
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2),
                    ),
                    Text("bis ${timer.type.friendlyName}")
                  ],
                ),
              ),
              IconButton(
                  onPressed: () {
                    appState.deleteTimer(timer);
                  },
                  icon: const Icon(Icons.close))
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void initState() {
    super.initState();
    Future<void> Function()? reload;
    reload = () async {
      if (mounted) {
        setState(() {});
        Future.delayed(const Duration(seconds: 10), reload);
      }
    };
    reload();
  }
}
