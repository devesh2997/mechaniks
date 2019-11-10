import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

enum Status { Pending, Accepted, Rejected }

class Ticket {
  final String id;
  final String uid;
  final String mid;
  final String username;
  final String merchantname;
  final String status;
  final String userphone;
  final String merchantphone;
  final GeoFirePoint userlocation;
  final GeoFirePoint merchantlocation;

  Ticket({
    this.id,
    this.uid,
    this.mid,
    this.username,
    this.merchantname,
    this.status,
    this.userphone,
    this.merchantphone,
    this.userlocation,
    this.merchantlocation,
  });

  factory Ticket.fromMap(Map data) {
    GeoPoint userpoint = data['userlocation']['geopoint'];
    GeoPoint mechanicpoint = data['merchantlocation']['geopoint'];
    return Ticket(
      id: data['id'],
      uid: data['uid'],
      mid: data['mid'],
      username: data['username'],
      merchantname: data['merchantname'],
      status: data['status'],
      userphone: data['userphone'],
      merchantphone: data['merchantphone'],
      userlocation: GeoFirePoint(userpoint.latitude, userpoint.longitude),
      merchantlocation:
          GeoFirePoint(mechanicpoint.latitude, mechanicpoint.longitude),
    );
  }

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data;
    data['id'] = doc.documentID;
    return Ticket.fromMap(data);
  }

  Map<String, dynamic> toMapForFirestore() {
    Map<String, dynamic> ticketMap = Map<String, dynamic>();
    ticketMap['uid'] = this.uid;
    ticketMap['mid'] = this.mid;
    ticketMap['username'] = this.username;
    ticketMap['merchantname'] = this.merchantname;
    ticketMap['status'] = this.status;
    ticketMap['userphone'] = this.userphone;
    ticketMap['merchantphone'] = this.merchantphone;
    ticketMap['userlocation'] = this.userlocation.data;
    ticketMap['merchantlocation'] = this.merchantlocation.data;
    return ticketMap;
  }
}
