import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/main.dart';
import 'package:sourbuddy/shared.dart';

import '../../icons/icons.dart';
import 'dough_details/dough_details.dart';

class DoughsOverview extends StatelessWidget {
  const DoughsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLoading = context.select((AppState state) => state.loading);
    if (isLoading) {
      return (const CircularProgressIndicator());
    }
    List<Dough> doughs = context.select((AppState state) => state.doughs.values.toList());
    debugPrint(doughs.toString());
    var children = doughs.map((dough) {
      return PaddedCard(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => DoughDetailsPage(doughId: dough.id)));
        },
        child: Row(
          children: [
            const SizedBox(height: 32, width: 32, child: SourdoughIcon(size: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dough.name, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2)),
                  const SizedBox(height: 4),
                  Text(dough.type),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Gewicht: ${dough.weight}g",
                        style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor),
                      ),
                      const Spacer(),
                      Text(
                        "Zuletzt gefüttert: ${printDuration(dough.lastFed.difference(DateTime.now()))}",
                        style: DefaultTextStyle.of(context).style.apply(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
    return ListView(children: children);
  }
}
