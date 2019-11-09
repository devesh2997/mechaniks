import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class MechaniksMap extends StatefulWidget {
  final Function onCurrenLocationChanged;
  final Set<Marker> markers;

  const MechaniksMap({Key key, this.onCurrenLocationChanged, this.markers}) : super(key: key);
  @override
  _MechaniksMapState createState() => _MechaniksMapState();
}

class _MechaniksMapState extends State<MechaniksMap> {
  GeoFirePoint location;

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;

  bool showMarker;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    location = GeoFirePoint(0, 0);
    showMarker = false;
    initLocation();
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      setState(() {
        location = GeoFirePoint(latitude, longitude);
      });
      // widget.onCurrenLocationChanged(latitude, longitude);
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> initLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    double latitude = position.latitude;
    double longitude = position.longitude;
    setState(() {
      location = GeoFirePoint(latitude, longitude);
    });

    CameraPosition cameraPosition =
        CameraPosition(target: LatLng(latitude, longitude), zoom: 14.4746);
    if (mapController != null) {
      CameraUpdate cameraUpdate =
          CameraUpdate.newCameraPosition(cameraPosition);
      await mapController.moveCamera(cameraUpdate);
      setState(() {
        showMarker = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = widget.markers;
    if(markers == null)
      markers = Set<Marker>();    
    Marker marker = Marker(
      markerId: MarkerId('loc'),
      position: LatLng(location.latitude, location.longitude),
    );
    markers.add(marker);
    return Container(
      child: GoogleMap(
        onCameraMove: (cameraPosition) {
          updateLocation(
              cameraPosition.target.latitude, cameraPosition.target.longitude);
        },
        onCameraIdle: () {
          widget.onCurrenLocationChanged(location.latitude, location.longitude);
        },
        gestureRecognizers: Set()
          ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
          ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()))
          ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
          ..add(Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer())),
        myLocationEnabled: true,
        scrollGesturesEnabled: true,
        mapType: MapType.normal,
        markers: showMarker ? markers : Set(),
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          setState(() {
            mapController = controller;
          });
        },
      ),
    );
  }
}
