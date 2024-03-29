import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mechaniks/data/mechanics_repository.dart';
import 'package:mechaniks/data/tickets_repository.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:mechaniks/models/mechanic.dart';
import 'package:mechaniks/models/ticket.dart';
import 'package:mechaniks/utils/index.dart';
import 'package:mechaniks/widgets/mechaniks_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'dart:async';
import 'dart:ui' as ui;


//Homepage for authenticated user.
class Landing extends StatefulWidget {
  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  GeoFirePoint currentLocation;
  BitmapDescriptor bitmapDescriptor;
  double radius;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    radius = 2;
    currentLocation = GeoFirePoint(0, 0);
    initLocation();
  }


  //Initialise current user location.
  Future<void> initLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    double latitude = position.latitude;
    double longitude = position.longitude;
    setState(() {
      currentLocation = GeoFirePoint(latitude, longitude);
    });
  }

  //Update current location.
  Future<void> updatecurrentLocation(double latitude, double longitude) async {
    try {
      setState(() {
        currentLocation = GeoFirePoint(latitude, longitude);
      });
      Provider.of<MechanicsRepository>(context)
          .updateMechaniks(currentLocation, radius);
    } on Exception catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    UserRepository userRepository = Provider.of<UserRepository>(context);
    List<Mechanic> mechanics =
        Provider.of<MechanicsRepository>(context).mechanics;
    Set<Marker> markers = Set<Marker>();
    for (int i = 0; i < mechanics.length; i++) {
      GeoFirePoint location = mechanics[i].location;
      String id = mechanics[i].name;
      //add mechanic markers to map.
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(location.latitude, location.longitude),
          icon: bitmapDescriptor ??
              BitmapDescriptor.fromAsset('assets/icon/mechanic.png'),
        ),
      );
    }
    return Scaffold(
      floatingActionButton: MaterialButton(
        color: getPrimaryColor(),
        shape: StadiumBorder(),
        onPressed: () => {Navigator.of(context).pushNamed('/tickets')},
        child: Text(
          "Tickets",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            height: size.width,
            child: MechaniksMap(
              onCurrenLocationChanged: updatecurrentLocation,
              markers: markers,
            ),
          ),
          MechanicsList(
            mechanics: mechanics,
            userlocation: currentLocation,
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Align(
              alignment: Alignment.topRight,
              child: RaisedButton(
                color: Colors.white,
                elevation: 0,
                onPressed: userRepository.signOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: getPrimaryColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//Widget for showing the list of nearby mechanics.
class MechanicsList extends StatelessWidget {
  final List<Mechanic> mechanics;
  final GeoFirePoint userlocation;

  const MechanicsList(
      {Key key, @required this.mechanics, @required this.userlocation})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size * 0.9;
    return Container(
      margin: EdgeInsets.only(top: size.width),
      child: ListView(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Merchants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      )
                    ],
                  ),
                ),
                if (mechanics.length == 0)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        SvgPicture.asset(
                          'assets/images/empty.svg',
                          width: size.width * 0.75,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'No merchant found nearby',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  )
                else
                  for (int i = 0; i < mechanics.length; i++)
                    MechanicView(
                      mechanic: mechanics[i],
                      userlocation: userlocation,
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MechanicView extends StatefulWidget {
  const MechanicView({
    Key key,
    @required this.mechanic,
    @required this.userlocation,
  }) : super(key: key);

  final Mechanic mechanic;
  final GeoFirePoint userlocation;

  @override
  _MechanicViewState createState() => _MechanicViewState();
}

class _MechanicViewState extends State<MechanicView> {
  String address;

  @override
  void initState() {
    super.initState();
    address = "";
    getAddress();
  }

  Future<void> getAddress() async {
    String add = await getAddressFromGeoFirePoint(widget.mechanic.location);
    setState(() {
      address = add;
    });
  }

  Future<void> call() async {
    String url = "tel:" + widget.mechanic.mobile;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Some error occurred while calling');
    }
  }

  @override
  Widget build(BuildContext context) {
    Mechanic mechanic = widget.mechanic;
    FirebaseUser user = Provider.of<UserRepository>(context).user;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  beautifyName(widget.mechanic.name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.mechanic.distance.toString() + ' km',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              address,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                MaterialButton(
                  onPressed: () async {
                    await call();
                  },
                  child: Text(
                    "Call",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 25,
                  color: Colors.grey.shade500,
                ),
                MaterialButton(
                  onPressed: () async {
                    Ticket ticket = Ticket(
                        merchantlocation: mechanic.location,
                        merchantname: mechanic.name,
                        merchantphone: mechanic.mobile,
                        username: user.displayName,
                        userphone: user.phoneNumber,
                        userlocation: widget.userlocation,
                        uid: user.uid,
                        mid: mechanic.id,
                        status: 'pending');
                    await Provider.of<TicketsRepository>(context)
                        .addTicket(ticket);
                  },
                  child: Text(
                    "Create Ticket",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
