import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:garaj_admin/garaj.dart';
import 'package:garaj_admin/user.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';

class ParksManagerScreen extends StatefulWidget {
  const ParksManagerScreen({Key? key}) : super(key: key);

  @override
  State<ParksManagerScreen> createState() => ParksManagerScreenState();
}

class ParksManagerScreenState extends State<ParksManagerScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  List<Park> parks = [];
  CollectionReference parkingRef =
      FirebaseFirestore.instance.collection('parking');
  CollectionReference usersRef = FirebaseFirestore.instance.collection('user');
  bool isLoad = false;
  List<User> managers = [];
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(31.950359, 35.886843),
    zoom: 19.4746,
  );
  CameraPosition currentPosition = const CameraPosition(
      target: LatLng(31.950359, 35.886843), zoom: 19.151926040649414);

  @override
  void initState() {
    getParking();
    getManagers();
  }

  List<User> getManagers() {
    managers = [];
    if (mounted) {
      setState(() {
        managers = [];
      });
    }
    usersRef.get().asStream().listen((event) {
      event.docs.forEach((element) {
        log('${element.data()}', name: 'hhhhhh');
        setState(() {
          User u = User.fromJson(json.decode(json.encode(element.data())));
          u.id = element.id;
          if (u.type == 0) {
            managers.add(u);
          }
        });
      });
      log('${managers.length}', name: 'hsssss');
    });
    return managers;
  }

  getParking() async {
    setState(() {
      isLoad = true;
    });
    parkingRef.get().then((value) {
      if (value.docs != null || value.docs.isNotEmpty) {
        value.docs.forEach((element) {
          Park park = Park.fromJson(json.decode(json.encode(element.data())));
          log('${park.toJson()}');
          parks.add(park);
          MarkerId markerId = MarkerId(
            park.id!,
          );
          LatLng latLng = LatLng(park.lat!, park.lng!);
          _markers.add(
            Marker(
                onTap: () {
                  showParkDetails(context, markerId);
                },
                markerId: markerId,
                position: latLng),
          );
          setState(() {
            isLoad = false;
          });
        });
      } else {
        setState(() {
          isLoad = false;
        });
      }
    }).then((value) {
      setState(() {
        isLoad = false;
      });
    });
  }

  addPark(BuildContext context) {
    if (managers.isNotEmpty) {
      User selectedUser = managers.first;
      TextEditingController parkNameController = TextEditingController();
      TextEditingController capacityController = TextEditingController();
      var uuid = const Uuid();
      final uid = uuid.v1();

      final formKey = GlobalKey<FormState>();

      Widget cancelButton = FlatButton(
        color: Colors.grey,
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      );
      Widget continueButton = FlatButton(
        child: const Text("Ok"),
        color: Colors.red,
        onPressed: () {
          formKey.currentState!.save();
          if (formKey.currentState!.validate()) {
            Park park = Park(
                available: int.parse(capacityController.text),
                capacity: int.parse(capacityController.text),
                id: uid,
                name: parkNameController.text,
                lat: currentPosition.target.latitude,
                lng: currentPosition.target.longitude,
                managerId: selectedUser.id);
            parkingRef
                .doc(park.id)
                .set(park.toJson())
                .then((value) {})
                .onError((error, stackTrace) {
              log('$error');
            });
            addParkMarker(park);
            Navigator.pop(context);
          }
        },
      );

      Get.bottomSheet(
          StatefulBuilder(builder: (BuildContext context,
              void Function(void Function()) setState1) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          Text(
                            "id:$uid",
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
                                      items: managers.map((user) {
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
                            decoration: const InputDecoration(
                                label: Text('Park Name')),
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
                            decoration: const InputDecoration(
                                label: Text('Capacity')),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            cancelButton,
                            continueButton,
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }),
          backgroundColor: Colors.white);
    } else {
      addParkingManger().then((value) {
        getManagers();
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  showParkDetails(BuildContext context, MarkerId markerId) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: const Text("cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget DeleteButton = FlatButton(
      child: const Text("Delete"),
      onPressed: () {
        deletePark(markerId);
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
        DeleteButton,
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

  deletePark(MarkerId markerId) {
    parkingRef.doc(markerId.value).delete().then((value) {
      _markers.removeWhere((element) => element.markerId == markerId);
      setState(() {});
    });
  }

  addParkMarker(Park garaj) {
    MarkerId markerId = MarkerId(garaj.id!);
    _markers.add(
      Marker(
          onTap: () {
            showParkDetails(context, markerId);
          },
          markerId: markerId,
          position: currentPosition.target),
    );
    setState(() {});
  }

  LatLngBounds getBounds(List<Marker> markers) {
    var lngs = markers.map<double>((m) => m.position.longitude).toList();
    var lats = markers.map<double>((m) => m.position.latitude).toList();

    double topMost = lngs.reduce(math.max);
    double leftMost = lats.reduce(math.min);
    double rightMost = lats.reduce(math.max);
    double bottomMost = lngs.reduce(math.min);

    LatLngBounds bounds = LatLngBounds(
      northeast: LatLng(rightMost, topMost),
      southwest: LatLng(leftMost, bottomMost),
    );

    return bounds;
  }

  Future addParkingManger() async {
    final formKey = GlobalKey<FormState>();

    TextEditingController managerEmailController = TextEditingController();
    TextEditingController managerPassController = TextEditingController();

    Widget cancelButton = FlatButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: const Text("Ok"),
      onPressed: () async {
        formKey.currentState!.save();
        if (formKey.currentState!.validate()) {
          loading();
          await auth.FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: managerEmailController.text,
                  password: managerPassController.text)
              .then((value) {
            User user = User(
                email: managerEmailController.text,
                type: 0,
                id: value.user!.uid);
            usersRef
                .doc(value.user!.uid)
                .set(user.toJson())
                .then((value) {})
                .onError((error, stackTrace) {
              log('$error');
            });
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          }).catchError((err) {
            Get.snackbar('Error', 'The email address is badly formatted');
          });
        }
      },
    );
    String formattedTime = DateFormat('h:mm:ss a').format(DateTime.now());
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
                      controller: managerEmailController,
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
                    TextFormField(
                      controller: managerPassController,
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Must fill!';
                        } else {
                          return null;
                        }
                      },
                      decoration: const InputDecoration(
                          label: Text('Park Manager Password')),
                    ),
                  ],
                ),
                Center(
                  child: MaterialButton(
                      color: Theme.of(context).primaryColor,
                      minWidth: Get.width,
                      height: 45,
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: Get.height / 2,
                                  width: Get.width,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: (Get.height / 2) - 100,
                                          width: Get.width,
                                          child: CupertinoDatePicker(
                                            mode: CupertinoDatePickerMode.time,
                                            onDateTimeChanged: (v) {
                                              formattedTime =
                                                  DateFormat('h:mm:ss a')
                                                      .format(v);
                                            },
                                          ),
                                        ),
                                        Center(
                                          child: MaterialButton(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              minWidth: Get.width,
                                              height: 45,
                                              onPressed: () {
                                                setState(() {});
                                                Get.back();
                                              },
                                              child: const Text(
                                                'Save',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              )),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                      },
                      child: Text(
                        formattedTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      )),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // resizeToAvoidBottomInset: false,
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
                      padding: const EdgeInsets.only(bottom: 60),
                      onCameraMove: (position) {
                        setState(() {
                          currentPosition = position;
                        });
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        controller.animateCamera(CameraUpdate.newLatLngBounds(
                          getBounds(_markers.toList()),
                          100,
                        ));
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

  void loading() {
    if (Platform.isIOS) {
      Get.dialog(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              CupertinoActivityIndicator(),
            ],
          ),
          barrierColor: Colors.black38,
          barrierDismissible: false);
    } else {
      Get.dialog(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          barrierColor: Colors.black38,
          barrierDismissible: false);
    }
  }
}
