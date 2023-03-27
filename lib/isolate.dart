import 'dart:isolate';

import 'package:flutter/material.dart';

class EventUpdater {
  EventUpdater(
    this.receivePort,
  ) {
    receivePort.listen(_onMessage);
  }
  final ReceivePort receivePort;
  late SendPort sendPort;
  Future<void> _onMessage(dynamic message) async {
    if (message is SendPort) {
      sendPort = message;
      print('start websocket');
      sendPort.send('status  OK');
    }
    if (message is AppLifecycleState) {
      final state = message;
      print('ISOLATE Lifecycle $state');
      throw (Exception());
    } else {
      print('send event ids to JRP');

      await Future.delayed(Duration(seconds: 1), () {});
      print('receive updates from socket');
      sendPort.send('Updated events');
    }
  }
}
