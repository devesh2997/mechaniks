import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:flutter/widgets.dart';
import 'package:mechaniks/models/mechanic.dart';


//Data repository for mechanics in the system
class MechanicsRepository extends ChangeNotifier {
  List<Mechanic> mechanics = [];
  Firestore _db;
  Geoflutterfire geo;
  GeoFirePoint center;
  double radius;

  MechanicsRepository.instance() {
    mechanics = [];
    _db = Firestore.instance;
    geo = Geoflutterfire();
  }

  //Update the list of nearby mechanics given the user location and search radius
  updateMechaniks(GeoFirePoint center, double radius) {
    if(center == null)return;
    print(center.latitude.toString()+' '+center.longitude.toString());
    var collectionRef = _db.collection('mechanics');
    geo
        .collection(collectionRef: collectionRef)
        .within(center: center, radius: radius, field: 'location',strictMode: true)
        .listen(_onMechanicsDataChanged);
  }

  //This listens for any change in the stream of mechanics data 
  Future<void> _onMechanicsDataChanged(List<DocumentSnapshot> snapshots) async {
    List<Mechanic> m = [];
    snapshots.forEach((doc) => m.add(Mechanic.fromFirestore(doc)));

    mechanics = m;
    notifyListeners();
  }

}
