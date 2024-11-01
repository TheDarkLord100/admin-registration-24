import 'dart:convert';

class RegistrationModel {
  String regID;
  String email;
  String teamName;
  String college;
  List<Member> members;
  Payment payment;

  RegistrationModel({
    required this.regID,
    required this.email,
    required this.teamName,
    required this.college,
    required this.members,
    required this.payment,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    List<Member> members = [];
    List<dynamic> mem = json['members'];
    for(dynamic m in mem) {
      members.add(Member.fromJson(m as Map<String, dynamic>));
    }
    return RegistrationModel(
      regID: json['regID'],
      email: json['email'],
      teamName: json['teamName'],
      college: json['college'],
      members: members,
      payment: Payment.fromJson(json['payment']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regID': regID,
      'email': email,
      'teamName': teamName,
      'college': college,
      'members': members.map((member) => member.toJson()).toList(),
      'payment': payment.toJson(),
    };
  }
}

class Member {
  String name;
  String collegeId;
  String personalId;

  Member({
    required this.name,
    required this.collegeId,
    required this.personalId,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      name: json['name'],
      collegeId: json['collegeId'],
      personalId: json['personalId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'collegeId': collegeId,
      'personalId': personalId,
    };
  }
}

class Payment {
  bool paid;
  String amount;

  Payment({
    required this.paid,
    required this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paid: json['paid'],
      amount: json['amount'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paid': paid,
      'amount': amount,
    };
  }
}
