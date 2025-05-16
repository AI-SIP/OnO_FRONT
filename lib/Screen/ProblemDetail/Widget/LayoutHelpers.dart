import 'package:flutter/material.dart';

Widget withPadding(BuildContext ctx, Widget child) => Padding(
      padding: EdgeInsets.all(MediaQuery.of(ctx).size.height * .008),
      child: SingleChildScrollView(child: child),
    );

Widget verticalSpacer(BuildContext ctx, double fraction) =>
    SizedBox(height: MediaQuery.of(ctx).size.height * fraction);

Widget tileTitle(String text, Color color) => Container(
      padding: const EdgeInsets.all(8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.touch_app, color: color, size: 16),
        const SizedBox(width: 10),
        Text(text,
            style: TextStyle(
                fontSize: 20, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
