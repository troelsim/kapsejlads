import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

void main() => runApp(new MyApp());

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
      home: new MyHomePage(title: "Startplanlægger"),
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

  LatLng _startA = new LatLng(0.0, 0.0);
  LatLng _startB = new LatLng(0.0, 0.0);

  LatLng _position = new LatLng(56.0, 10.0);

  void _toggleEditMode(){
    setState((){
      _editing = !_editing;
    });
  }

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
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
        child: new FlutterMap(
          options: new MapOptions(
            center: new LatLng(56.64, 9.12),
            zoom: 13.0,
            onTap: _updateStartLine
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
              ]
            )
          ],
        )
      ));
    }
}
