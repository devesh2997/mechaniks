import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:mechaniks/models/mechanic.dart';

class MechanicsRepository extends ChangeNotifier {
  List<Mechanic> mechanics = [];
  Firestore _db;

  MechanicsRepository.instance()
      : mechanics = [],
        _db = Firestore.instance {
    _db.collection('mechanics').snapshots().listen(_onMechanicsDataChanged);
  }

  Future<void> _onMechanicsDataChanged(QuerySnapshot querySnapshot) async {
    List<Mechanic> m = [];
    querySnapshot.documents
        .forEach((doc) => m.add(Mechanic.fromFirestore(doc)));

    mechanics = m;
    notifyListeners();
  }

  Future<bool> addMechanic(Mechanic mechanic) async {
    await _db.collection('mechanics').add(mechanic.toMapForFirestore());
    return true;
  }

  Future<bool> deleteMechanic(Mechanic mechanic) async {
    await _db.collection('mechanics').document(mechanic.id).delete();
    return true;
  }
}
