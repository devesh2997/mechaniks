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

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  FirebaseUser _user;
  bool loadingUserInfo;
  Firestore _db;
  Status _status = Status.Uninitialized;
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

  Future<void> sendEmailVerificationLink(String email) async {
    return await _auth.sendSignInWithEmailLink(
      email: email,
      url: 'https://www.underk.in/verify-email',
      handleCodeInApp: true,
      iOSBundleID: 'in.underk.underk-app',//TODO change bundeid
      androidPackageName: 'in.underk.underk_app',
      androidInstallIfNotAvailable: true,
      androidMinimumVersion: "1",
    );
  }

  Future<bool> linkEmailWithLink(String link) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String email = preferences.getString('verification_email');
    if (email == null || email == "") return false;

    AuthCredential credential =
        EmailAuthProvider.getCredentialWithLink(email: email, link: link);
    try {
      await _user.linkWithCredential(credential);
      await _user.reload();
      _user = await _auth.currentUser();
      notifyListeners();
      showToast("Email verified!");
      return true;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ERROR_INVALID_CREDENTIAL":
          message = "Invalid credential. Try again";
          break;
        case "ERROR_CREDENTIAL_ALREADY_IN_USE":
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

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> linkGoogleAccount() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser;
    GoogleSignInAuthentication googleAuth;
    try {
      googleUser = await googleSignIn.signIn();
      googleAuth = await googleUser.authentication;
    } catch (error) {
      print(error);
      showToast('Some Error Occurred');
      return false;
    }
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      await _user.linkWithCredential(credential);
      await _user.reload();
      _user = await _auth.currentUser();
      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "ERROR_INVALID_CREDENTIAL":
          message = "Invalid credential. Try again";
          break;
        case "ERROR_CREDENTIAL_ALREADY_IN_USE":
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

  Future<bool> signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    GoogleSignInAccount googleUser;
    GoogleSignInAuthentication googleAuth;
    try {
      googleUser = await googleSignIn.signIn();
      googleAuth = await googleUser.authentication;
    } catch (error) {
      print(error);
      return false;
    }
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
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

  Future<bool> verifyPhoneNumber(_phoneNumber) async {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _auth.signInWithCredential(phoneAuthCredential);
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      message = authException.message;
      _status = Status.Unauthenticated;
      notifyListeners();
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _status = Status.CodeSent;
      notifyListeners();
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

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

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(FirebaseUser firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }


  Future<void> setDisplayName(String displayName) async {
    UserUpdateInfo userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = displayName;
    await _user.updateProfile(userUpdateInfo);
    await _user.reload();
    _user = await _auth.currentUser();
    notifyListeners();
  }

  Future<void> setEmail(String email) async {
    try {
      await _user.updateEmail(email);
      await _user.reload();
      await _user.sendEmailVerification();
      _user = await _auth.currentUser();
      notifyListeners();
    } catch (e) {
      //TODO handle exception for email already in use
      //TODO handle exception for recent sign in
      print(e);
    }
  }


  Future<void> sendEmailVerification() async {
    await _user.sendEmailVerification();
    notifyListeners();
  }
}
