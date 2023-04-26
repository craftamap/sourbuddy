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
                printDuration(timer.timestamp.difference(DateTime.now()), absolute: false),
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
