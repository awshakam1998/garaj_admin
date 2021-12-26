

import 'dart:convert';

List<Garaj> garajFromJson(String str) => List<Garaj>.from(json.decode(str).map((x) => Garaj.fromJson(x)));

String garajToJson(List<Garaj> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Garaj {
  Garaj({
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

  factory Garaj.fromJson(Map<String, dynamic> json) => Garaj(
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
