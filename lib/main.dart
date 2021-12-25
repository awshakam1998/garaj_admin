import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:garaj_admin/garaj.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

bool shouldUseFirestoreEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (shouldUseFirestoreEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  List<Garaj> garajs = [];
  CollectionReference parkingRef =
      FirebaseFirestore.instance.collection('parking');
  bool isLoad=false;

  @override
  void initState() {
    getParking();

  }

   getParking() async {
     setState(() {
       isLoad=true;
     });
    parkingRef.get().then((value){
      value.docs.forEach((element) {
        Garaj g =Garaj.fromJson(json.decode(json.encode(element.data())));
        log('${g.toJson()}');
        garajs.add(g);
        MarkerId markerId = MarkerId(
          g.id!,
        );
        List<String> latlngList=g.latlng!.split(',');
        LatLng latLng = LatLng(double.parse(latlngList[0]), double.parse(latlngList[1]));
        _markers.add(
          Marker(
              onTap: () {
                showMarkerDetails(context, markerId);
              },
              markerId: markerId,
              position: latLng),
        );
        setState(() {
          isLoad=false;
        });
      });

    });
  }

  static const CameraPosition _kGooglePlex = const CameraPosition(
    target: const LatLng(31.950359, 35.886843),
    zoom: 19.4746,
  );
  CameraPosition currentposisoin = CameraPosition(
      target: LatLng(31.950359, 35.886843), zoom: 19.151926040649414);

  static const CameraPosition _kLake = const CameraPosition(
      target: LatLng(31.950359, 35.886843), zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text('Parks manager'),
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_markers.length} parks'),
          ))
        ],
      ),
      body:isLoad?CircularProgressIndicator(): SafeArea(
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.satellite,
                      initialCameraPosition: _kGooglePlex,
                      markers: _markers,
                      layoutDirection: TextDirection.ltr,
                      padding: EdgeInsets.only(bottom: 60),
                      onCameraMove: (position) {
                        setState(() {
                          currentposisoin = position;
                        });
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                              height: 160,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SvgPicture.asset(
                                    'assets/pin.svg',
                                    height: 100,
                                    color: Colors.red,
                                  ),
                                ],
                              ))),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 0,
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: MaterialButton(
                          child: Text(
                            'Add Park',
                            style: TextStyle(color: Colors.white),
                          ),
                          onLongPress: () {
                            CollectionReference parking = FirebaseFirestore
                                .instance
                                .collection('parking');
                            parking
                                .add(garajFromJson(
                                    json.decode(json.encode(garajs))))
                                .then((value) {
                              print(value);
                            }).onError((error, stackTrace) {
                              print('err: $error');
                            });
                          },
                          onPressed: () {
                            addPark(context);
                          },
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],
                ),
              )

    );
  }

  addPark(BuildContext context) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Ok"),
      onPressed: () {
        addMarker();
        Navigator.pop(context);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Add Park"),
      content: Text("Would you like to add park here?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showMarkerDetails(BuildContext context, MarkerId markerId) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Delete"),
      onPressed: () {
        deleteMarker(markerId);
        Navigator.pop(context);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Park Info"),
      content:
          Text("${currentposisoin.target}\nAre you sure to delete this park?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  deleteMarker(MarkerId markerId) {
    _markers.removeWhere((element) => element.markerId == markerId);
    setState(() {});
  }

  addMarker() {
    MarkerId markerId = MarkerId(
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _markers.add(
      Marker(
          onTap: () {
            showMarkerDetails(context, markerId);
          },
          markerId: markerId,
          position: currentposisoin.target),
    );

    setState(() {});
  }
}
