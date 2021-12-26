

import 'dart:convert';

List<User> usersFromJson(String str) => List<User>.from(json.decode(str).map((x) => User.fromJson(x)));

String usersToJson(List<User> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
  User({
    this.email,
    this.id,
    this.type
  });

  int? type;
  String? email;
  String? id;

  factory User.fromJson(Map<String, dynamic> json) => User(
    type: json["type"],
    id: json["id"],
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "id": id,
    "email": email,
  };
}
