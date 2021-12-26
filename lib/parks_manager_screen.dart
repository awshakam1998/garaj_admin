import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:garaj_admin/garaj.dart';
import 'package:garaj_admin/user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class ParksManagerScreen extends StatefulWidget {
  const ParksManagerScreen({Key? key}) : super(key: key);

  @override
  State<ParksManagerScreen> createState() => ParksManagerScreenState();
}

class ParksManagerScreenState extends State<ParksManagerScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  List<Garaj> garajs = [];
  CollectionReference parkingRef =
      FirebaseFirestore.instance.collection('parking');
  CollectionReference usersRef = FirebaseFirestore.instance.collection('user');
  bool isLoad = false;
  List<User> users = [];

  @override
  void initState() {
    getParking();
    getUsers();
  }

  getUsers() {
    if (mounted) {
      setState(() {
        users = [];
      });
    }
    usersRef.get().asStream().listen((event) {
      event.docs.forEach((element) {
        log('${element.data()}', name: 'hhhhhh');
        setState(() {
          User u =User.fromJson(json.decode(json.encode(element.data())));
          u.id=element.id;
          users.add(u);
        });
      });
      log('${users.length}', name: 'hsssss');
    });
  }

  getParking() async {
    setState(() {
      isLoad = true;
    });
    parkingRef.get().then((value) {
      value.docs.forEach((element) {
        Garaj g = Garaj.fromJson(json.decode(json.encode(element.data())));
        log('${g.toJson()}');
        garajs.add(g);
        MarkerId markerId = MarkerId(
          g.id!,
        );
        LatLng latLng = LatLng(g.lat!, g.lng!);
        _markers.add(
          Marker(
              onTap: () {
                showMarkerDetails(context, markerId);
              },
              markerId: markerId,
              position: latLng),
        );
        setState(() {
          isLoad = false;
        });
      });
    });
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(31.950359, 35.886843),
    zoom: 19.4746,
  );
  CameraPosition currentPosition = const CameraPosition(
      target: LatLng(31.950359, 35.886843), zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('Parks manager'),
          actions: [
            Center(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${_markers.length} parks'),
            ))
          ],
        ),
        body: isLoad
            ? const Center(child: const CircularProgressIndicator())
            : SafeArea(
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.satellite,
                      initialCameraPosition: _kGooglePlex,
                      markers: _markers,
                      layoutDirection: TextDirection.ltr,
                      padding: const EdgeInsets.only(bottom: 60),
                      onCameraMove: (position) {
                        setState(() {
                          currentPosition = position;
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
                          child: const Text(
                            'Add Park',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            addPark(context);
                          },
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],
                ),
              ));
  }

  addPark(BuildContext context) {
    User selectedUser = users.first;
    TextEditingController parkNameController = TextEditingController();
    TextEditingController capacityController = TextEditingController();
    var uuid = const Uuid();
    final uid = uuid.v1();
    final formKey = GlobalKey<FormState>();

    Widget cancelButton = FlatButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: const Text("Ok"),
      onPressed: () {
        formKey.currentState!.save();
        if (formKey.currentState!.validate()) {
          Garaj garaj = Garaj(
              available: int.parse(capacityController.text),
              capacity: int.parse(capacityController.text),
              id: uid,
              name: parkNameController.text,
              lat: currentPosition.target.latitude,
              lng: currentPosition.target.longitude,
              managerId: selectedUser.id);
          parkingRef
              .doc(garaj.id)
              .set(garaj.toJson())
              .then((value) {})
              .onError((error, stackTrace) {
            log('$error');
          });
          addMarker(garaj);
          Navigator.pop(context);
        }
      },
    );
    AlertDialog alert = AlertDialog(
      title: const Text("Add Park"),
      content: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Text(
                      "id:\n$uid",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: DropdownButton<User>(
                                isExpanded: true,
                                hint: const Text('Parking manager'),
                                // Not necessary for Option 1
                                value: selectedUser,
                                onChanged: (value) {
                                  setState(() {
                                    selectedUser = value!;
                                  });
                                },
                                underline: Container(),
                                items: users.map((user) {
                                  return DropdownMenuItem(
                                    child: Text(user.email!),
                                    value: user,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            addParkingManger();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextFormField(
                      controller: parkNameController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Must fill!';
                        } else {
                          return null;
                        }
                      },
                      decoration:
                          const InputDecoration(label: Text('Park Name')),
                    ),
                    TextFormField(
                      controller: capacityController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Must fill!';
                        } else {
                          return null;
                        }
                      },
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(label: Text('Capacity')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
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
      child: const Text("cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: const Text("Delete"),
      onPressed: () {
        deleteMarker(markerId);
        Navigator.pop(context);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Park Info"),
      content:
          Text("${currentPosition.target}\nAre you sure to delete this park?"),
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
    parkingRef.doc(markerId.value).delete().then((value){
      _markers.removeWhere((element) => element.markerId == markerId);
      setState(() {});
    });
  }

  addMarker(Garaj garaj) {
    MarkerId markerId = MarkerId(garaj.id!);
    _markers.add(
      Marker(
          onTap: () {
            showMarkerDetails(context, markerId);
          },
          markerId: markerId,
          position: currentPosition.target),
    );
    setState(() {});
  }

  addParkingManger() {
    final formKey = GlobalKey<FormState>();

    TextEditingController managerNameController = TextEditingController();
    Widget cancelButton = FlatButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: const Text("Ok"),
      onPressed: () {
        formKey.currentState!.save();
        if (formKey.currentState!.validate()) {
          User user = User(email: managerNameController.text, type: 0);
          usersRef.doc().set(user.toJson()).then((value) {
            getUsers();
          }).onError((error, stackTrace) {
            log('$error');
          });
          Navigator.pop(context);
        }
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Add Park Manager"),
      content: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    TextFormField(
                      controller: managerNameController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Must fill!';
                        } else {
                          return null;
                        }
                      },
                      decoration: const InputDecoration(
                          label: Text('Park Manager Email')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
