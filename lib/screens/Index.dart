import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';

class Index extends StatefulWidget {
  @override
  _IndexState createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final key = GlobalKey<ScaffoldState>();
  // Set default `_initialized` and `_error` state to false
  bool _initialized = false;
  bool _error = false;
  var _stateColor = Colors.black;
  double _currentSliderValue = 20;
  var time = TimeOfDay.now();
  StreamSubscription<Event> _stateSubscription;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  Future<void> sendCommand(String command) async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('smartSwitchCommand');
    final results = await callable({'deviceId': 'switch_00', 'state': command});
    debugPrint("results");
    debugPrint(results.data.toString());
    var resCode = results.data['code'];
    debugPrint(resCode.toString());
    if (resCode == 9) {
      debugPrint("Device offline");
      key.currentState.showSnackBar(SnackBar(content: Text('Device offilne')));
      setState(() {
        _stateColor = Colors.black;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();

    final FirebaseDatabase _database = FirebaseDatabase.instance;
    debugPrint(_database.reference().toString());
    var _stateRef = _database
        .reference()
        .child('smartSwitches')
        .child('switch_00')
        .child('state');
    _stateSubscription = _stateRef.onValue.listen((Event event) {
      debugPrint(event.snapshot.value.toString());
      setState(() {
        _stateColor =
            event.snapshot.value == 'on' ? Colors.yellow : Colors.black;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      debugPrint(error.toString());
      // setState(() {
      //   _error = error;
      // });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stateSubscription.cancel();
  }

  void handleOnPress() {
    debugPrint("on pressed");
    sendCommand('on');
    // setState(() {
    //   _stateColor = Colors.yellow;
    // });
  }

  void handleOffPress() {
    debugPrint("off pressed");
    sendCommand('off');
    // setState(() {
    //   _stateColor = Colors.black;
    // });
  }

  void handleSlider() {}

  void handleDate() {}

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      debugPrint(_error.toString());
      // return SomethingWentWrong();
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      debugPrint('not initialized');
      // return Loading();
    }
    if (_initialized) {
      debugPrint("FlutterFire OK!");
      // return Loading();
    }

    var selectedDate;
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text("SmartWitch"),
      ),
      body: Container(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(
            Icons.wb_incandescent,
            color: _stateColor,
            size: 75.0,
            semanticLabel: 'Text to announce in accessibility modes',
          ),
          Slider(
            value: _currentSliderValue,
            min: 0,
            max: 255,
            divisions: 255,
            label: _currentSliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderValue = value;
              });
            },
          ),
          FlatButton(
            child: Text("Date: " + selectedDate.toString()),
            onPressed: () async {
              await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RaisedButton(
                onPressed: handleOnPress,
                color: Colors.blueAccent,
                child: const Text('On',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
              RaisedButton(
                onPressed: handleOffPress,
                color: Colors.blueAccent,
                child: const Text('Off',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              )
            ],
          ),
        ],
      )),
    );
  }
}
