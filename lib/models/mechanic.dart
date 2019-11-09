import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class Mechanic {
  final String id;
  final String name;
  final String mobile;
  final GeoFirePoint location;
  final double distance;

  Mechanic({this.id, this.name, this.mobile, this.location,this.distance, });

  factory Mechanic.fromMap(Map data) {
    GeoPoint point = data['location']['geopoint'];
    return Mechanic(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      mobile: data['mobile'] ?? '',
      location: GeoFirePoint(point.latitude, point.longitude),
      distance :data['distance']
    );
  }

  factory Mechanic.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data;
    data['id'] = doc.documentID;
    return Mechanic.fromMap(data);
  }

  Map<String, dynamic> toMapForFirestore() {
    Map<String, dynamic> mechanicMap = Map<String, dynamic>();
    mechanicMap['name'] = this.name;
    mechanicMap['mobile'] = this.mobile;
    mechanicMap['location'] = this.location.data;

    return mechanicMap;
  }
}
