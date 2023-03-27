import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:isolate_test_app/isolate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _counter = 0;

  Isolate? isolate;
  SendPort? sendPort;
  ReceivePort? receivePort;
  Capability? cap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initIsolate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
    if (state == AppLifecycleState.paused) {
      sendPort?.send(state);
      cap = isolate?.pause();
    }
    if (state == AppLifecycleState.resumed) {
      sendPort?.send(state);
      isolate?.resume(cap!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    isolate?.kill(priority: Isolate.immediate);
    super.dispose();
  }

  Future<void> _onMessage(dynamic message) async {
    print('Events received');
    print(message);
    await Future.delayed(Duration(seconds: 1), () {});
    sendPort?.send('Subscription <Events>');
  }

  Future<void> _onError(dynamic message) async {
    print('Error');
    print(message);
  }

  Future<void> _onExit(dynamic message) async {
    print('Exit');
    print(message);
    isolate?.kill(priority: Isolate.immediate);
    await initIsolate();
  }

  Future<void> initIsolate() async {
    final ReceivePort receiver = ReceivePort();
    ReceivePort errorPort = ReceivePort();
    ReceivePort exitPort = ReceivePort();
    isolate = await Isolate.spawn<SendPort>(
      isolateCreator,
      receiver.sendPort,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    sendPort = await receiver.first;
    receivePort = ReceivePort();
    receivePort?.listen(_onMessage);
    exitPort.listen(_onExit);
    errorPort.listen(_onError);
    sendPort?.send(receivePort?.sendPort);
  }

  static Future<void> isolateCreator(SendPort sendPort) async {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    Isolate.current.addErrorListener(sendPort);
    Isolate.current.addOnExitListener(sendPort);
    EventUpdater(receivePort);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
