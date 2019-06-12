import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';

import 'dart:math';

void main() => runApp(new MyApp());

LatLng lineIntersection(LatLng line1a, LatLng line1b, LatLng line2a, LatLng line2b) {
  print(line1a);
  print(line1b);
  print(line2a);
  print(line2b);

  if (line1a == line1b) return line1a;
  if (line2a == line2b) return line2a;

  final double x1 = line1a.longitude;
  final double y1 = line1a.latitude;
  final double x2 = line1b.longitude;
  final double y2 = line1b.latitude;
  final double x3 = line2a.longitude;
  final double y3 = line2a.latitude;
  final double x4 = line2b.longitude;
  final double y4 = line2b.latitude;

  final double lon = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4))/((x1 - x2)*(y3-y4) - (y1-y2)*(x3-x4));
  final double lat = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4))/((x1 - x2)*(y3-y4) - (y1-y2)*(x3-x4));
  print("$lat, $lon");

  if (lon >= 90.0 || lon <= -90.0 || lat <= -180.0 || lat >= 180.0){
    return line1b;
  }

  return LatLng(lat, lon);
}

final _numberFormat = NumberFormat.decimalPattern();

String formatNumber(double number){
  return _numberFormat.format(number);
}

String formatTime(int totalSeconds){
  final bool negative = totalSeconds < 0;
  totalSeconds = totalSeconds.abs();
  final int seconds = totalSeconds % 60;
  final int minutes = ((totalSeconds - seconds)/60).floor();
  return (negative ? "-" : "") + DateFormat.Hms().format(new DateTime(1987, 12, 7, 0, minutes, seconds));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Start',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: "Super Start"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _editing = false;

  static const int MAX_PATH_SIZE = 500;

  double _speed = 0.0;

  LatLng _startA = new LatLng(0.0, 0.0);
  LatLng _startB = new LatLng(0.0, 0.0);

  LatLng _position = new LatLng(56.0, 10.0);

  LatLng _viewport = new LatLng(56.0, 10.0);

  DateTime _startTime = DateTime.now();

  ListQueue<LatLng> path = new ListQueue<LatLng>();
  ListQueue<double> dx = new ListQueue<double>();
  ListQueue<double> dy = new ListQueue<double>();

  final location = new Location();

  _MyHomePageState() {
    _loadPreferences();
    print("Getting location");
    location.getLocation().then((res) {print("Got location $res");});
    print("Subscribing to location changes...");
    location.onLocationChanged().listen((Map<String, double> currentLocation) {
      print(currentLocation);
      setState((){
        _logPosition(new LatLng(currentLocation["latitude"], currentLocation["longitude"]));
        _logSpeed(currentLocation["speed"]);
      });
    });
    print("Subscribed to location changes.");
  }

  void _logPosition(LatLng position){
    setState((){
      int stepsBack = min(5, path.length);
      if (stepsBack > 0){
        final LatLng latestPoint = path.elementAt(stepsBack - 1);
        dx.addFirst(position.latitude - latestPoint.latitude);
        dy.addFirst(position.longitude - latestPoint.longitude);
      }
      if(path.length > MAX_PATH_SIZE) {
        path.removeLast();
      }
      path.addFirst(position);
      _position = position;
    });
  }

  void _logSpeed(double speed){
    setState((){
      _speed = _speed*0.8 + speed*0.2;
    });
  }

  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _startA = LatLng(prefs.getDouble("startA_lat") ?? 0.0, prefs.getDouble("startA_lon") ?? 0.0);
    _startB = LatLng(prefs.getDouble("startB_lat") ?? 0.0, prefs.getDouble("startB_lon") ?? 0.0);
    _startTime = prefs.getInt("startTime") > 0 ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt("startTime")) :  DateTime.now();
    if(prefs.getDouble("viewport_lat") != null){
      _viewport = LatLng(prefs.getDouble("viewport_lat"), prefs.getDouble("viewport_lon"));
    }
  }

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("startA_lat", _startA.latitude);
    await prefs.setDouble("startA_lon", _startA.longitude);
    await prefs.setDouble("startB_lat", _startB.latitude);
    await prefs.setDouble("startB_lon", _startB.longitude);
    await prefs.setDouble("viewport_lat", _viewport.latitude);
    await prefs.setDouble("viewport_lon", _viewport.longitude);
    await prefs.setInt("startTime", _startTime.millisecondsSinceEpoch);
  }

  LatLng project(LatLng position, double dx, double dy, double length){
    double norm = sqrt(pow(dx, 2) + pow(dy, 2));
    if (norm > 0.0){
      return LatLng(position.latitude + dx/norm*length, position.longitude + dy/norm*length);
    }
    return position;
  }

  String toDegrees(double latlon){
    final int degrees = latlon.floor();
    final double rest = latlon - degrees;
    final double seconds = rest * 60.0;
    return "$degrees° ${formatNumber(seconds)}'";
  }

  void _toggleEditMode(){
    setState((){
      _editing = !_editing;
    });
  }

  static const textStyle = TextStyle(
    fontSize: 24.0,
    color: Colors.black,
    fontWeight: FontWeight.w900
  );

  void _updateStartLine(LatLng position) {
    if (!_editing) return;
    if (_startA == LatLng(0.0, 0.0)) {
      setState((){ _startA = position; });
      return;
    }
    if (_startB == LatLng(0.0, 0.0)) {
      setState((){ _startB = position; });
      return;
    }
    num distA = Distance().as(LengthUnit.Kilometer, _startA, position);
    num distB = Distance().as(LengthUnit.Kilometer, _startB, position);
    setState((){
      if (distA < distB) {
        _startA = position;
      }else{
        _startB = position;
      }
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Duration minutesDifference;
    final LatLng intersection = lineIntersection(_startA, _startB, _position, project(_position, dx.first, dy.first , 0.1));
    final secondsToStart = max(0.0, _speed > 0.0 ? Distance().as(LengthUnit.Meter, _position, intersection)/_speed : 0.0);
    if (_startTime != null){
      minutesDifference = Duration(seconds: secondsToStart.round()) - _startTime.difference(DateTime.now());
    }
    else{
      minutesDifference = Duration.zero;
    }

    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _editing ? Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: FloatingActionButton(
              child: Icon(Icons.timer),
              onPressed: (){
                showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _startTime.hour, minute: _startTime.minute)
                ).then((time){
                  setState((){
                    final now = DateTime.now();
                    _startTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                  });
                  _savePreferences();
                });
              }
            )
          ) : Container(),
          FloatingActionButton(
            backgroundColor: _editing ? Colors.green : Colors.blue ,
            onPressed: _toggleEditMode,
            child: Icon(_editing ? Icons.save : Icons.edit) ,
          ),
        ]
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Stack(
          children: <Widget> [
            new FlutterMap(
              options: new MapOptions(
                center: _viewport,
                zoom: 13.0,
                onTap: _updateStartLine,
                onPositionChanged: (MapPosition position){
                  _viewport = position.center;
                  _savePreferences();
                }
              ),
              layers: [
                new TileLayerOptions(
                  urlTemplate: "https://api.tiles.mapbox.com/v4/"
                      "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken': 'pk.eyJ1IjoidHJvZWxzaW0iLCJhIjoiY2psczVueTJuMDgybjNxcXkycmt0eXNmdCJ9.zG6pOvjU_dAeW5Tk0YcThA',
                    'id': 'mapbox.streets',
                  },
                ),
                PolylineLayerOptions(
                  polylines: [
                    new Polyline(
                      points: <LatLng>[
                        _startA,
                        _startB
                      ],
                      strokeWidth: 8.0,
                      color: _editing ? Colors.red : Colors.green
                    ),
                    new Polyline(
                      points: path.toList(),
                      strokeWidth: 4.0,
                      color: Colors.red
                    ),
                    new Polyline(
                      points: dx.length > 5 ? <LatLng>[
                        _position,
                        project(_position, dx.first, dy.first , 0.1)
                      ] : [],
                      strokeWidth: 2.0,
                      color: Colors.blue
                    )
                  ]
                ),
                new MarkerLayerOptions(
                  markers: dx.length > 0 ? <Marker>[
                    new Marker(
                      width: 50.0,
                      height: 50.0,
                      point: intersection,
                      builder: (x) => Container(child: Icon(Icons.add))
                    )
                  ] : []
                ),
              ],
            ),
            _editing ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text("${toDegrees(_startA.longitude)}, ${toDegrees(_startA.latitude)}",
                  style: textStyle,
                  textAlign: TextAlign.center
                ),
                Text("${toDegrees(_startB.longitude)}, ${toDegrees(_startB.latitude)}",
                  style: textStyle,
                  textAlign: TextAlign.center
                ),
              ]
            )
            :
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Text(
                  "Distance to start (course):\n${formatNumber(Distance().as(LengthUnit.Meter, _position, intersection)/1852)} nm",
                  style: textStyle,
                  textAlign: TextAlign.left,
                ),
                Text(
                  "Time to start:\n${formatTime((Distance().as(LengthUnit.Meter, _position, intersection)/_speed).round())}",
                  style: textStyle,
                  textAlign: TextAlign.left,
                ),
                Text(
                  "Speed:\n${formatNumber(_speed/1852.0*3600.0)} kt",
                  style: textStyle,
                  textAlign: TextAlign.left,
                ),
                _startTime.difference(DateTime.now()).isNegative ? Container() :
                Text(
                   "${formatTime((minutesDifference.inSeconds).round())}",
                   style: TextStyle(
                     color: minutesDifference.inSeconds < 0 ? Colors.red : Colors.green,
                     fontSize: 30.0,
                     fontWeight: FontWeight.w900
                   )
                ),
                _startTime.difference(DateTime.now()).isNegative ? Container() :
                Text(
                  minutesDifference.inSeconds < 0 ? "Early!" : "Late",
                 style: TextStyle(
                   color: minutesDifference.inSeconds < 0 ? Colors.red : Colors.green,
                   fontSize: 30.0,
                   fontWeight: FontWeight.w900
                 )
                )
              ]
            )
          ]
        )
      ));
    }
}
