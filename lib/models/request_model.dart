import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String senderId;
  final String fullName;
  final String bloodGroup;
  final String quantity;
  final String hospitalName;
  final DateTime timestamp;
  final String status;
  // New verification fields
  final int age;
  final String address;
  final String pincode;
  final String phone;
  final bool hasOperation;
  final bool hasInjection;
  final bool hadCovid;
  final bool isHivPositive;
  final bool isUrgent;
  final bool shareContactDetails;
  final bool isCritical;
  final DateTime? lastDonationDate;

  RequestModel({
    required this.id,
    required this.senderId,
    required this.fullName,
    required this.bloodGroup,
    required this.quantity,
    required this.hospitalName,
    required this.timestamp,
    this.status = 'pending',
    required this.age,
    required this.address,
    required this.pincode,
    required this.phone,
    required this.hasOperation,
    required this.hasInjection,
    required this.hadCovid,
    required this.isHivPositive,
    required this.isUrgent,
    required this.shareContactDetails,
    this.isCritical = false,
    this.lastDonationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'quantity': quantity,
      'hospitalName': hospitalName,
      'timestamp': timestamp,
      'status': status,
      'age': age,
      'address': address,
      'pincode': pincode,
      'phone': phone,
      'hasOperation': hasOperation,
      'hasInjection': hasInjection,
      'hadCovid': hadCovid,
      'isHivPositive': isHivPositive,
      'isUrgent': isUrgent,
      'shareContactDetails': shareContactDetails,
      'isCritical': isCritical,
      'lastDonationDate': lastDonationDate,
    };
  }

  factory RequestModel.fromMap(String id, Map<String, dynamic> map) {
    return RequestModel(
      id: id,
      senderId: map['senderId'] ?? '',
      fullName: map['fullName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      quantity: map['quantity'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      age: map['age'] ?? 0,
      address: map['address'] ?? '',
      pincode: map['pincode'] ?? '',
      phone: map['phone'] ?? '',
      hasOperation: map['hasOperation'] ?? false,
      hasInjection: map['hasInjection'] ?? false,
      hadCovid: map['hadCovid'] ?? false,
      isHivPositive: map['isHivPositive'] ?? false,
      isUrgent: map['isUrgent'] ?? false,
      shareContactDetails: map['shareContactDetails'] ?? false,
      isCritical: map['isCritical'] ?? false,
      lastDonationDate:
          map['lastDonationDate'] != null
              ? (map['lastDonationDate'] as Timestamp).toDate()
              : null,
    );
  }
}
