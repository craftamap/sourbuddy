import 'package:flutter/material.dart';
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

class DoughDetails extends StatelessWidget {
  final int doughId;
  LoadingState events = LoadingState.notLoaded;
  DoughDetails({super.key, required this.doughId});

  @override
  Widget build(BuildContext context) {
    if (events == LoadingState.notLoaded) {
      debugPrint('foo');
      events = LoadingState.loading;
      context.read<AppState>().loadDoughEvents(doughId);
      events = LoadingState.loaded;
    }

    var dough = context.select((AppState state) => state.doughs[doughId]!);
    var doughEvents =
        context.select((AppState state) => state.doughEvents[doughId]);

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
            onPressed: () {}, child: const Icon(Icons.add)));
  }
}

class DoughEventView extends StatelessWidget {
  const DoughEventView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class DoughEventPage extends StatelessWidget {
  const DoughEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('name'),
        actions: const [],
      ),
      body: const DoughEventView(),
    );
  }
}
