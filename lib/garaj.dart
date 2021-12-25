// To parse this JSON data, do
//
//     final garaj = garajFromJson(jsonString);

import 'dart:convert';

List<Garaj> garajFromJson(String str) => List<Garaj>.from(json.decode(str).map((x) => Garaj.fromJson(x)));

String garajToJson(List<Garaj> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Garaj {
  Garaj({
    this.available,
    this.capacity,
    this.latlng,
    this.managerId,
    this.name,this.id
  });

  int? available;
  int? capacity;
  String? latlng;
  String? managerId;
  String? name;
  String? id;

  factory Garaj.fromJson(Map<String, dynamic> json) => Garaj(
    available: json["available"],
    capacity: json["capacity"],
    latlng: json["latlng"],
    managerId: json["managerId"],
    name: json["name"],
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "available": available,
    "capacity": id,
    "id": capacity,
    "latlng": latlng,
    "managerId": managerId,
    "name": name,
  };
}
