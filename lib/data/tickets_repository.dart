import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:flutter/widgets.dart';
import 'package:mechaniks/models/ticket.dart';
import 'package:mechaniks/models/ticket.dart';

class TicketsRepository extends ChangeNotifier {
  List<Ticket> tickets = [];
  Firestore _db;
  FirebaseAuth _auth;
  Geoflutterfire geo;
  GeoFirePoint center;
  double radius;

  TicketsRepository.instance() {
    tickets = [];
    _db = Firestore.instance;
    geo = Geoflutterfire();
    _auth = FirebaseAuth.instance;
    _auth.onAuthStateChanged.listen(_onAuthStateChanged);
  
    
  }

  Future<void> _onAuthStateChanged(FirebaseUser user) async {
    if (user == null) {
    } else {
      _db.collection('tickets').where('uid',isEqualTo: user.uid).snapshots().listen(_onTicketsDataChanged);
    }
    notifyListeners();
  }


  Future<void> _onTicketsDataChanged(QuerySnapshot snapshots) async {
    List<Ticket> m = [];
    List<DocumentSnapshot> docs = snapshots.documents;
    docs.forEach((doc) => m.add(Ticket.fromFirestore(doc)));

    tickets = m;
    notifyListeners();
  }

  Future<bool> addTicket(Ticket ticket) async {
    await _db.collection('tickets').add(ticket.toMapForFirestore());
    return true;
  }

  Future<bool> deleteTicket(Ticket ticket) async {
    await _db.collection('tickets').document(ticket.id).delete();
    return true;
  }
}
