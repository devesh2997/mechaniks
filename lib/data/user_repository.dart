import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  Uninitialized,
  Authenticated,
  Authenticating,
  Unauthenticated,
  CodeSent,
  LoadingUserInfo
}


//Class that handles user authentication.
class UserRepository with ChangeNotifier {
  FirebaseAuth _auth; // Firebase auth object
  FirebaseUser _user; // Firebase user object
  bool loadingUserInfo;
  Firestore _db;
  Status _status = Status.Uninitialized; // Status of authentication
  String message = "";

  String _verificationId;

  UserRepository.instance()
      : _auth = FirebaseAuth.instance,
        _db = Firestore.instance {
    loadingUserInfo = false;
    _auth.onAuthStateChanged.listen(_onAuthStateChanged);
  }

  Status get status => _status;
  FirebaseUser get user => _user;

  //Handle sign in with google.
  Future<bool> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser;
    GoogleSignInAuthentication googleAuth;
    //Try google authentication.
    try {
      googleUser = await googleSignIn.signIn();
      googleAuth = await googleUser.authentication;
    } catch (error) {
      print(error);
      return false;
    }
    //Fetch sign in credentials from google auth.
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //Try firebase sign in.
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithCredential(credential);
      return true;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ERROR_INVALID_CREDENTIAL":
          message = "Invalid credential. Try again";
          break;
        case "ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL":
          message = "Another account already exists with this email Id.";
          break;
        default:
          message = "Some error occured. Try again later.";
          break;
      }
      showToast(message);
      return false;
    }
  }

  //Handle phone number submission for authentication.
  Future<bool> verifyPhoneNumber(_phoneNumber) async {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _auth.signInWithCredential(phoneAuthCredential);
    };

    //On Verification failed.
    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      message = authException.message;
      _status = Status.Unauthenticated;
      notifyListeners();
    };

    //On Code sent.
    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _status = Status.CodeSent;
      notifyListeners();
    };

    //Automatic code retrieval timeout.
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

    //Try phone number verification. Send OTP.
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber,
          timeout: const Duration(seconds: 5),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  //Submit OTP and try authentication.
  Future<bool> signInWithPhoneNumber(_smsCode) async {
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: _verificationId,
      smsCode: _smsCode,
    );
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithCredential(credential);
      return true;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ERROR_INVALID_CREDENTIAL":
          message = "Invalid code. Try again";
          break;
        case "ERROR_INVALID_VERIFICATION_CODE":
          message = "Invalid code. Try again";
          break;
        default:
          print(message);
          message = "Some error occured. Try again later.";
          break;
      }
      showToast(message);
      _status = Status.CodeSent;
      notifyListeners();
      return false;
    }
  }

  //Sign out.
  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  //Listen for authentication status change.
  Future<void> _onAuthStateChanged(FirebaseUser firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

}
