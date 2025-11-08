
import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications ({super.key});

  @override
  State<StatefulWidget> createState() => _Notifications();
}

class _Notifications extends State<Notifications>{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Comming Soon!!!'),
      ),
    );

  }


}
