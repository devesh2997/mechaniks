import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechaniks/models/ticket.dart';

//Get individual address part string, ending with comma or not.
String _getAddressPart(String part, {bool comma = true}) {
  if (part == null || part.length == 0) return "";
  if (comma) {
    return part + ', ';
  } else {
    return part;
  }
}


//Returns address from placemark
String placemarkAddress(Placemark placemark) {
  String add = "";
  add += _getAddressPart(placemark.name);
  add += _getAddressPart(placemark.subThoroughfare);
  if(placemark.subThoroughfare!=placemark.thoroughfare)add += _getAddressPart(placemark.thoroughfare);
  add += _getAddressPart(placemark.subLocality);
  if(placemark.subLocality!=placemark.locality)add += _getAddressPart(placemark.locality);
  add += _getAddressPart(placemark.subAdministrativeArea);
  if(placemark.subAdministrativeArea!=placemark.administrativeArea)add += _getAddressPart(placemark.administrativeArea);
  add += _getAddressPart(placemark.postalCode, comma: false);
  return add;
}


//Get placemark from GeoFirePoint (convert LatLong to placemark object)
Future<String> getAddressFromGeoFirePoint(GeoFirePoint point) async {
  try {
    List<Placemark> placemarks =
        await Geolocator().placemarkFromCoordinates(point.latitude, point.longitude);
    return placemarkAddress(placemarks[0]);
  } on Exception catch (e) {
    print(e);
    return "";
  }
}

//Widget showing the status for a ticket
Widget getTicketStatusWidget(Ticket ticket){
  TextStyle style;
  if(ticket.status.compareTo('pending')==0){
    style = TextStyle(color: Colors.orange,fontSize: 16,fontWeight: FontWeight.w500);
  }else if(ticket.status.compareTo('accepted')==0){
    style = TextStyle(color: Colors.green,fontSize: 16,fontWeight: FontWeight.w500);
  }else{
    style = TextStyle(color: Colors.red,fontSize: 16,fontWeight: FontWeight.w500);
  }
  return Text('Status : ' + beautifyString(ticket.status),style: style,);
}


//Get hex code from hex string.
int _getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return int.parse(hexColor, radix: 16);
}

//Capitalise first letter of string
String beautifyString(String str) {
  if (str.length == 0) return str;
  if (str.length == 1) return str[0].toUpperCase();
  return str[0].toUpperCase() + str.substring(1);
}

//Capitalise each word in the name string.
String beautifyName(String str) {
  if (str.length == 0) return str;
  if (str.length == 1) return str[0].toUpperCase();
  List<String> n = str.split(' ');
  for (int i = 0; i < n.length; i++) {
    if (n[i].length > 1) n[i] = n[i][0].toUpperCase() + n[i].substring(1);
  }
  String nn = "";
  for (int i = 0; i < n.length; i++) {
    nn += n[i] + ' ';
  }
  return nn;
}

//Get rupee symbol
String getRupee() {
  return '\u20B9';
}


//Custom Hexcolor class
class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

MaterialColor hexToMaterialColor(final String hexColor) {
  Map<int, Color> color = {
    50: HexColor(hexColor).withOpacity(0.1),
    100: HexColor(hexColor).withOpacity(0.2),
    200: HexColor(hexColor).withOpacity(0.3),
    300: HexColor(hexColor).withOpacity(0.4),
    400: HexColor(hexColor).withOpacity(0.5),
    500: HexColor(hexColor).withOpacity(0.6),
    600: HexColor(hexColor).withOpacity(0.7),
    700: HexColor(hexColor).withOpacity(0.8),
    800: HexColor(hexColor).withOpacity(0.9),
    900: HexColor(hexColor).withOpacity(1),
  };

  return MaterialColor(_getColorFromHex(hexColor), color);
}


//Get Primary MaterialColor of the app.
MaterialColor getPrimaryColor() {
  return Colors.orange;
}

//Get Accent color of the app.
MaterialColor getAccentColor() {
  return hexToMaterialColor('#2952FF');
}

// MaterialColor getAccentColor() {
//   return hexToMaterialColor('#5AE6FF');
// }
