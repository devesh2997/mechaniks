import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mechaniks/data/tickets_repository.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:mechaniks/models/ticket.dart';
import 'package:mechaniks/utils/index.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size * 0.9;
    List<Ticket> tickets = Provider.of<TicketsRepository>(context).tickets;
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tickets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (tickets.length == 0)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
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
                          'No ticket created yet.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, i) {
                    return TicketItem(
                      ticket: tickets[i],
                    );
                  },
                  itemCount: tickets.length,
                ),
              )
          ],
        ),
      ),
    );
  }
}

class TicketItem extends StatefulWidget {
  final Ticket ticket;

  const TicketItem({Key key, this.ticket}) : super(key: key);

  @override
  _TicketItemState createState() => _TicketItemState();
}

class _TicketItemState extends State<TicketItem> {
  String address;

  @override
  void initState() {
    super.initState();
    address = "";
    getAddress();
  }

  Future<void> getAddress() async {
    String add = await getAddressFromGeoFirePoint(widget.ticket.userlocation);
    setState(() {
      address = add;
    });
  }

  Future<void> call() async {
    String url = "tel:" + widget.ticket.userphone;
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
            if (widget.ticket.username != null &&
                widget.ticket.username.length > 0)
              Text(
                'Client name : ' + widget.ticket.username,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (widget.ticket.userphone != null &&
                widget.ticket.userphone.length > 0)
              Text(
                'Client phone : ' + widget.ticket.userphone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              'Client Address : ' + address,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            getTicketStatusWidget(widget.ticket),
          ],
        ),
      ),
    );
  }
}
