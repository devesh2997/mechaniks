import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/country_code_selector.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;


//Screen handling User authentication.
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      backgroundColor: Colors.white,
      body: Builder(
        builder: (BuildContext context) {
          return SignInSection();
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}


//Widget for showing sign in options.
class SignInSection extends StatefulWidget {
  SignInSection();
  @override
  State<StatefulWidget> createState() => SignInSectionState();
}

class SignInSectionState extends State<SignInSection> {
  String countryCode;

  final _formKey = GlobalKey<FormState>();
  TextEditingController loginCredController;

  @override
  void initState() {
    super.initState();

    loginCredController = MaskedTextController(mask: '00000 00000');

    countryCode = '+91';
  }

  _setCountryCode(code) {
    if (code.toString() != '+91')
      setState(() {
        countryCode = code.toString();
      });
  }

  @override
  Widget build(BuildContext context) {
    UserRepository userRepository = Provider.of<UserRepository>(context);
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.all(20),
        child: _toggle(userRepository),
      ),
      body: buildLogin(userRepository.status),
      resizeToAvoidBottomPadding: true,
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _toggle(UserRepository userRepository) {
    Status status = userRepository.status;
    if (status == Status.Authenticating) {
      return Container(
        child: CircularProgressIndicator(),
      );
    }
    return Container(
      child: FloatingActionButton(
        elevation: 2,
        onPressed: () {
          if (_formKey.currentState.validate()) {
            if (status != Status.CodeSent) {
              userRepository
                  .verifyPhoneNumber(countryCode + loginCredController.text);
            } else {
              userRepository.signInWithPhoneNumber(loginCredController.text);
            }
          }
        },
        tooltip: 'Send OTP',
        child: Padding(
          padding: const EdgeInsets.only(left: 3.0),
          child: Icon(Icons.navigate_next),
        ),
      ),
    );
  }

  Widget buildLogin(Status status) {
    String message = Provider.of<UserRepository>(context).message;
    return status == Status.Authenticating
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 20, 20, 20),
                      child: Container(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 20, 20, 30),
                  child: Text(
                    status != Status.CodeSent
                        ? 'Enter your mobile number to continue. '
                        : 'Sit back and relax while we verify your mobile number. ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
                  child: buildInput(status),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: Center(
                      child:
                          Text(message, style: TextStyle(color: Colors.red))),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: Center(child: buildSubText(status)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: Center(
                      child: Text(
                    "OR",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100),
                  )),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 0),
                  child: Center(
                    child: GoogleSignInButton(
                      onPressed: () {
                        Provider.of<UserRepository>(context).signInWithGoogle();
                      },
                      darkMode: true,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget buildSubText(Status status) {
    if (status == Status.CodeSent) {
      return Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'We have sent a verification code to your mobile.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: GestureDetector(
          //     child: Padding(
          //       padding: const EdgeInsets.only(top: 8.0),
          //       child: Text(
          //         'Change Mobile number.',
          //         style: TextStyle(
          //           fontSize: 14,
          //           color: Colors.blue.shade600,
          //           fontFamily: 'Questrial',
          //         ),
          //       ),
          //     ),
          //     onTap: () {
          //       setState(
          //         () {
          //           _isMobile = true;
          //           loginCredController =
          //               MaskedTextController(mask: '00000 00000');
          //           _isLoading = false;
          //           _message = '';
          //         },
          //       );
          //     },
          //   ),
          // ),
        ],
      );
    } else {
      return Text(
        'Your mobile number is used for authentication.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }
  }

  Widget buildInput(Status status) {
    if (status == Status.CodeSent) {
      loginCredController.text = '';
      loginCredController = MaskedTextController(mask: '000000');
      return Padding(
        padding: const EdgeInsets.fromLTRB(60.0, 0, 60, 0),
        child: TextField(
          autofocus: true,
          cursorColor: Colors.blue.shade500,
          controller: loginCredController,
          keyboardType: TextInputType.numberWithOptions(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      );
    } else {
      return Theme(
        data: ThemeData(primaryColor: Colors.blue),
        child: Row(
          children: <Widget>[
            CountryCodeSelector(
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                letterSpacing: 2,
                fontFamily: 'Questrial',
              ),
              onChanged: (value) => _setCountryCode(value),
              // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
              initialSelection: 'IN',
              favorite: ['+91', 'IN'],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
                child: TextField(
                  cursorColor: Colors.black,
                  controller: loginCredController,
                  keyboardType: TextInputType.numberWithOptions(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
