import 'package:flutter/material.dart';
import 'package:sourbuddy/shared.dart';

class DoughsOverview extends StatelessWidget {
  const DoughsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        children: List.filled(
            10,
            PaddedCard(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DoughDetailsPage()));
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
                        "Trockener Lukas",
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(fontSizeFactor: 1.2),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      const Text('Roggenmehl'),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(children: [
                        Text(
                          "weight: 40g",
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(color: Theme.of(context).hintColor),
                        ),
                        const Spacer(),
                        Text(
                          "last fed: 1d 7h",
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(color: Theme.of(context).hintColor),
                        )
                      ]),
                    ],
                  ))
                ],
              ),
            )));
  }
}

class DoughDetails extends StatelessWidget {
  const DoughDetails({super.key});

  @override
  Widget build(BuildContext context) {
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
                  "Trockener Lukas",
                  style: DefaultTextStyle.of(context)
                      .style
                      .apply(fontSizeFactor: 1.2),
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text('Roggenmehl'),
                const SizedBox(
                  height: 4,
                ),
                Row(children: [
                  Text(
                    "weight: 40g",
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(color: Theme.of(context).hintColor),
                  ),
                  const Spacer(),
                  Text(
                    "last fed: 1d 7h",
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
        children: [
          ...List.filled(
              15,
              PaddedCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2023-04-03 23:35',
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(color: Theme.of(context).hintColor),
                      ),
                      Text(
                        'Teig gefüttert',
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(fontSizeFactor: 1.1),
                      ),
                      const Text(
                        'Ziehzeit: 12h',
                      ),
                      const Text(
                        'Altes Gewicht: 40g; Neues Gewicht: 120g',
                      )
                    ]),
              ))
        ],
      ))
    ]);
  }
}

class DoughDetailsPage extends StatelessWidget {
  const DoughDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('name'),
          actions: const [],
        ),
        body: const DoughDetails(),
        floatingActionButton: FloatingActionButton(
            onPressed: () {}, child: const Icon(Icons.add)));
  }
}

class DoughEvent extends StatelessWidget {
  const DoughEvent({super.key});

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
      body: const DoughEvent(),
    );
  }
}
