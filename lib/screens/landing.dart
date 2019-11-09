import 'package:flutter/material.dart';
import 'package:mechaniks/data/mechanics_repository.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:mechaniks/models/mechanic.dart';
import 'package:mechaniks/utils/index.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Landing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    UserRepository userRepository = Provider.of<UserRepository>(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/add-mechanic'),
        child: Icon(
          Icons.add,
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: RaisedButton(
                  color: Colors.white,
                  elevation: 0,
                  onPressed: userRepository.signOut,
                  child: Text(
                    'Logout',
                    style: TextStyle(
                        color: getPrimaryColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(child: MechanicsList()),
          ],
        ),
      ),
    );
  }
}

class MechanicsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Mechanic> mechanics =
        Provider.of<MechanicsRepository>(context).mechanics ?? [];
    return ListView(
      children: <Widget>[
        for (int i = 0; i < mechanics.length; i++)
          new MechanicView(mechanic: mechanics[i])
      ],
    );
  }
}

class MechanicView extends StatefulWidget {
  const MechanicView({
    Key key,
    @required this.mechanic,
  }) : super(key: key);

  final Mechanic mechanic;

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
            Text(
              beautifyName(widget.mechanic.name),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
                IconButton(
                  onPressed: () async {
                    await call();
                  },
                  icon: Icon(
                    Icons.call,
                    color: Colors.green,
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 25,
                  color: Colors.grey.shade500,
                ),
                IconButton(
                  onPressed: () async {
                    await Provider.of<MechanicsRepository>(context)
                        .deleteMechanic(widget.mechanic);
                  },
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
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
