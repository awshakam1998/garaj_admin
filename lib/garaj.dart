

import 'dart:convert';

List<Park> garajFromJson(String str) => List<Park>.from(json.decode(str).map((x) => Park.fromJson(x)));

String garajToJson(List<Park> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Park {
  Park({
    this.available,
    this.capacity,
    this.managerId,
    this.name,this.id,
    this.lat,
    this.lng
  });

  int? available;
  int? capacity;

  double? lat;
  double? lng;
  String? managerId;
  String? name;
  String? id;

  factory Park.fromJson(Map<String, dynamic> json) => Park(
    available: json["available"],
    capacity: json["capacity"],
    lat: json["lat"],
    lng: json["lng"],
    managerId: json["managerId"],
    name: json["name"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "available": available,
    "capacity": capacity,
    "id": id,
    "lat": lat,
    "lng": lng,
    "managerId": managerId,
    "name": name,
  };
}
