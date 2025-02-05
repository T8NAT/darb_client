// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as pl;
import 'package:flutter_user/translations/translation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/NavigatorPages/editprofile.dart';
import '../pages/NavigatorPages/history.dart';
import '../pages/NavigatorPages/historydetails.dart';
import '../pages/loadingPage/loadingpage.dart';
import '../pages/login/login.dart';
import '../pages/onTripPage/booking_confirmation.dart';
import '../pages/onTripPage/map_page.dart';
import '../pages/onTripPage/review_page.dart';
import '../pages/referralcode/referral_code.dart';
import '../styles/styles.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;
int waitingTime = 0;
String gender = 'male';

//base url
//base url
String url =
    'https://drb-sa.com/'; //add '/' at the end of the url as 'https://url.com/'

String mapkey = 'AIzaSyBB_XpDbAQqZuOBBAFcDl7IsecGWvDnD8Q';
String mapType = 'google';

//check internet connection

checkInternetConnection() {
  print('====== checkInternetConnection =====');
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

getDetailsOfDevice() async {
  print('====== getDetailsOfDevice =====');
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    darktheme();

    pref = await SharedPreferences.getInstance();
  } catch (e) {
    print('errrr $e');
    debugPrint(e.toString());
  }
}

darktheme() async {
  print('====== darktheme =====');
  if (isDarkTheme == true) {
    white = Colors.black;
    textColor = Colors.white;
    buttonColor = Colors.white;
    loaderColor = Colors.white;
    hintColor = Colors.white.withOpacity(0.3);
  } else {
    white = Colors.white;
    textColor = Colors.black;
    buttonColor = primaryAppColor;
    loaderColor = primaryAppColor;
    hintColor = const Color(0xff12121D).withOpacity(0.3);
  }
  boxshadow = BoxShadow(
      blurRadius: 2, color: textColor.withOpacity(0.2), spreadRadius: 2);

  if (isDarkTheme == true) {
    await rootBundle.loadString('assets/dark.json');
  } else {
    await rootBundle.loadString('assets/map_style_black.json');
  }
  valueNotifierHome.incrementNotifier();
}

// dynamic timerLocation;
dynamic locationAllowed;

bool positionStreamStarted = false;
StreamSubscription<Position>? positionStream;

LocationSettings locationSettings = (platform == TargetPlatform.android)
    ? AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      )
    : AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 100,
      );

positionStreamData() {
  print('====== positionStreamData =====');
  positionStream =
      Geolocator.getPositionStream(locationSettings: locationSettings)
          .handleError((error) {
    positionStream = null;
    positionStream?.cancel();
  }).listen((Position? position) {
    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
    } else {
      positionStream!.cancel();
    }
  });
}

//validate email already exist

validateEmail(email) async {
  print('====== validateEmail =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile'),
        body: (values == 0) ? {'mobile': email} : {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = languages[choosenLanguage]['text_email_already_taken'];
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'Amharic', 'code': 'am'},
  {'name': 'Arabic', 'code': 'ar'},
  {'name': 'Basque', 'code': 'eu'},
  {'name': 'Bengali', 'code': 'bn'},
  {'name': 'English (UK)', 'code': 'en-GB'},
  {'name': 'Portuguese (Brazil)', 'code': 'pt-BR'},
  {'name': 'Bulgarian', 'code': 'bg'},
  {'name': 'Catalan', 'code': 'ca'},
  {'name': 'Cherokee', 'code': 'chr'},
  {'name': 'Croatian', 'code': 'hr'},
  {'name': 'Czech', 'code': 'cs'},
  {'name': 'Danish', 'code': 'da'},
  {'name': 'Dutch', 'code': 'nl'},
  {'name': 'English (US)', 'code': 'en'},
  {'name': 'Estonian', 'code': 'et'},
  {'name': 'Filipino', 'code': 'fil'},
  {'name': 'Finnish', 'code': 'fi'},
  {'name': 'French', 'code': 'fr'},
  {'name': 'German', 'code': 'de'},
  {'name': 'Greek', 'code': 'el'},
  {'name': 'Gujarati', 'code': 'gu'},
  {'name': 'Hebrew', 'code': 'iw'},
  {'name': 'Hindi', 'code': 'hi'},
  {'name': 'Hungarian', 'code': 'hu'},
  {'name': 'Icelandic', 'code': 'is'},
  {'name': 'Indonesian', 'code': 'id'},
  {'name': 'Italian', 'code': 'it'},
  {'name': 'Japanese', 'code': 'ja'},
  {'name': 'Kannada', 'code': 'kn'},
  {'name': 'Korean', 'code': 'ko'},
  {'name': 'Latvian', 'code': 'lv'},
  {'name': 'Lithuanian', 'code': 'lt'},
  {'name': 'Malay', 'code': 'ms'},
  {'name': 'Malayalam', 'code': 'ml'},
  {'name': 'Marathi', 'code': 'mr'},
  {'name': 'Norwegian', 'code': 'no'},
  {'name': 'Polish', 'code': 'pl'},
  {
    'name': 'Portuguese (Portugal)',
    'code': 'pt' //pt-PT
  },
  {'name': 'Romanian', 'code': 'ro'},
  {'name': 'Russian', 'code': 'ru'},
  {'name': 'Serbian', 'code': 'sr'},
  {
    'name': 'Chinese (PRC)',
    'code': 'zh' //zh-CN
  },
  {'name': 'Slovak', 'code': 'sk'},
  {'name': 'Slovenian', 'code': 'sl'},
  {'name': 'Spanish', 'code': 'es'},
  {'name': 'Swahili', 'code': 'sw'},
  {'name': 'Swedish', 'code': 'sv'},
  {'name': 'Tamil', 'code': 'ta'},
  {'name': 'Telugu', 'code': 'te'},
  {'name': 'Thai', 'code': 'th'},
  {'name': 'Chinese (Taiwan)', 'code': 'zh-TW'},
  {'name': 'Turkish', 'code': 'tr'},
  {'name': 'Urdu', 'code': 'ur'},
  {'name': 'Ukrainian', 'code': 'uk'},
  {'name': 'Vietnamese', 'code': 'vi'},
  {'name': 'Welsh', 'code': 'cy'},
];

//getting country code

List countries = [];

getCountryCode() async {
  print('====== getCountryCode =====');
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];

      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

phoneAuth(String phone) async {
  try {
    print('====== phoneAuth =====');
    credentials = null;
    print('phonephone ${phone}');
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        credentials = credential;
        valueNotifierHome.incrementNotifier();
      },
      forceResendingToken: resendTokenId,
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          debugPrint('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verId = verificationId;
        resendTokenId = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  } catch (e) {
    print('errrr $e');
    print('eeeee $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//get local bearer token

String lastNotification = '';
List recentSearchesList = [];

getLocalData() async {
  print('====== getLocalData =====');
  dynamic result;
  bearerToken.clear;
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    internet = false;
  } else {
    internet = true;
  }
  try {
    if (pref.containsKey('lastNotification')) {
      lastNotification = pref.getString('lastNotification');
    }
    if (pref.containsKey('autoAddress')) {
      var val = pref.getString('autoAddress');
      storedAutoAddress = jsonDecode(val);
    }

    if (pref.containsKey('choosenLanguage')) {
      choosenLanguage = pref.getString('choosenLanguage');
      languageDirection = pref.getString('languageDirection');
      if (choosenLanguage.isNotEmpty) {
        if (pref.containsKey('Bearer')) {
          var tokens = pref.getString('Bearer');
          if (tokens != null) {
            bearerToken.add(BearerClass(type: 'Bearer', token: tokens));

            var responce = await getUserDetails();
            if (responce == true) {
              result = '3';
            } else {
              result = '2';
            }
          } else {
            result = '2';
          }
        } else {
          result = '2';
        }
      } else {
        result = '1';
      }
    } else {
      result = '1';
    }
    if (pref.containsKey('isDarkTheme')) {
      isDarkTheme = pref.getBool('isDarkTheme');
      if (isDarkTheme == true) {
        white = Colors.black;
        textColor = Colors.white;
        buttonColor = Colors.white;
        loaderColor = Colors.white;
        hintColor = Colors.white.withOpacity(0.3);
      } else {
        white = Colors.white;
        textColor = Colors.black;
        buttonColor = primaryAppColor;
        loaderColor = primaryAppColor;
        hintColor = const Color(0xff12121D).withOpacity(0.3);
      }
      boxshadow = BoxShadow(
          blurRadius: 2, color: textColor.withOpacity(0.2), spreadRadius: 2);
    }
    if (pref.containsKey('recentsearch')) {
      var val = pref.getString('recentsearch');
      recentSearchesList = jsonDecode(val);
      // print(';jhvhjvjkbkj');
      // printWrapped(jsonDecode(val).toString());
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//register user

List<BearerClass> bearerToken = <BearerClass>[];

registerUser() async {
  print('====== registerUser =====');
  bearerToken.clear();
  dynamic result;
  try {
    var token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    var fcm = token.toString();
    final response =
        http.MultipartRequest('POST', Uri.parse('${url}api/v1/user/register'));

    response.headers.addAll({'Content-Type': 'application/json'});
    if (proImageFile1 != null) {
      response.files.add(
          await http.MultipartFile.fromPath('profile_picture', proImageFile1));
    }
    response.fields.addAll({
      "name": name,
      "mobile": phnumber,
      "email": email,
      "password": password,
      "device_token": fcm,
      "country": countries[phcode]['dial_code'],
      "login_by": (platform == TargetPlatform.android) ? 'android' : 'ios',
      'lang': choosenLanguage,
      'gender': (gender == 'male')
          ? 'male'
          : (gender == 'female')
              ? 'female'
              : 'others',
    });
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    // print(choosenLanguage.toString());

    if (request.statusCode == 200) {
      var jsonVal = jsonDecode(respon.body);

      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      pref.setString('Bearer', bearerToken[0].token);
      await getUserDetails();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
      result = 'true';
    } else if (respon.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(respon.body);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//update referral code

updateReferral() async {
  print('====== updateReferral =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/update/user/referral'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({"refferal_code": referralCode}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'true';
      } else {
        debugPrint(response.body);
        result = 'false';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//call firebase otp

otpCall() async {
  print('====== otpCall =====');
  dynamic result;
  try {
    var otp = await FirebaseDatabase.instance.ref().child('call_FB_OTP').get();

    print('otpotpotp ${otp.value}');
    result = otp;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

// verify user already exist

verifyUser(String number, int login, String password, String email, isOtp,
    forgot) async {
  print('====== verifyUser =====');
  dynamic val;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/validate-mobile-for-login'),
        body: (number != '' && email != '')
            ? {"mobile": number, "email": email}
            : (login == 0)
                ? {
                    "mobile": number,
                  }
                : {
                    "email": number,
                  });

    if (response.statusCode == 200) {
      val = jsonDecode(response.body)['success'];
      if (val == true) {
        if ((number != '' && email != '') || forgot == true) {
          if (forgot == true) {
            val = true;
          } else if (jsonDecode(response.body)['message'] == 'email_exists') {
            val = 'Email Already Exists';
          } else if (jsonDecode(response.body)['message'] == 'mobile_exists') {
            val = 'Mobile Already Exists';
          } else {
            val = 'Email and Mobile Already Exists';
          }
        } else {
          var check = await userLogin(number, login, password, isOtp);
          if (check == true) {
            var uCheck = await getUserDetails();
            val = uCheck;
          } else {
            val = check;
          }
        }
      } else {
        // enabledModule = jsonDecode(response.body)['enabled_module'];
        // if (enabledModule != 'both') {
        //   transportType = enabledModule;
        // } else {
        //   transportType = '';
        // }
        val = false;
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      val = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      val = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      val = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return val;
}

acceptRequest(body) async {
  print('====== acceptRequest =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/respond-for-bid'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: body);

    if (response.statusCode == 200) {
      ismulitipleride = true;
      await getUserDetails(id: userRequestData['id']);
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

updatePassword(email, password, loginby) async {
  print('====== updatePassword =====');
  dynamic result;

  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-password'), body: {
      if (loginby == true) 'email': email,
      if (loginby == false) 'mobile': email,
      'password': password
    });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = true;
      } else {
        result = jsonDecode(response.body)['message'];
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//user login
userLogin(number, login, password, isOtp) async {
  print('====== userLogin =====');
  bearerToken.clear();
  dynamic result;
  try {
    var token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {}
    print('tokentokentoken ${token}');
    var fcm = token.toString();
    var response = await http.post(Uri.parse('${url}api/v1/user/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: (isOtp == false)
            ? jsonEncode({
                if (login == 0) "mobile": number,
                if (login == 1) "email": number,
                'password': password,
                'device_token': fcm,
                "login_by":
                    (platform == TargetPlatform.android) ? 'android' : 'ios',
              })
            : (login == 0)
                ? jsonEncode({
                    "mobile": number,
                    'device_token': fcm,
                    "login_by": (platform == TargetPlatform.android)
                        ? 'android'
                        : 'ios',
                  })
                : jsonEncode({
                    "email": number,
                    "otp": password,
                    'device_token': fcm,
                    "login_by": (platform == TargetPlatform.android)
                        ? 'android'
                        : 'ios',
                  }));
    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      package = await PackageInfo.fromPlatform();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

userSocialLogin(BuildContext context, token, loginMethod) async {
  FocusScope.of(context).unfocus();
  print('====== userSocialLogin =====');
  bearerToken.clear();
  dynamic result;
  try {
    var fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    print('tokentokentoken ${fcmToken}');
    var fcm = fcmToken.toString();
    var response =
        await http.post(Uri.parse('${url}api/v1/social-auth/$loginMethod'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "provider": loginMethod,
              "oauth_token": token,
              'device_token': fcm,
              "login_by":
                  (platform == TargetPlatform.android) ? 'android' : 'ios',
            }));
    print('responseresponse ${response.statusCode}');
    print('responseresponse ${response.body}');
    if (response.statusCode == 200) {
      var jsonVal = jsonDecode(response.body);
      bearerToken.add(BearerClass(
          type: jsonVal['token_type'].toString(),
          token: jsonVal['access_token'].toString()));
      result = true;
      pref.setString('Bearer', bearerToken[0].token);
      package = await PackageInfo.fromPlatform();
      if (platform == TargetPlatform.android && package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_package_name': package.packageName.toString()});
      } else if (package != null) {
        await FirebaseDatabase.instance
            .ref()
            .update({'user_bundle_id': package.packageName.toString()});
      }

      result = await getUserDetails();
      print('getUserDetailsgetUserDetails $result');
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = false;
    }
    print('getUserDetailsgetUserDetails 2  $result');
  } catch (e) {
    print('errrr $e');
    print('errrrrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

Map<String, dynamic> userDetails = {
  /*'name': '',
  'mobile': '',
  'email': '',
  'profile_picture': '',
  'gender': '',*/
};
List favAddress = [];
List tripStops = [];
List banners = [];
bool ismulitipleride = false;
bool polyGot = false;
bool changeBound = false;
//user current state

getUserDetails({id}) async {
  print('====== getUserDetails =====');
  dynamic result;
  try {
    var response = await http.get(
      (ismulitipleride)
          ? Uri.parse('${url}api/v1/user?current_ride=$id')
          : Uri.parse('${url}api/v1/user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}'
      },
    );

    if (response.statusCode == 200) {
      print('response.bodyresponse.body ${response.body}');
      print('response.bodyresponse.body ${jsonDecode(response.body)}');

      userDetails =
          Map<String, dynamic>.from(jsonDecode(response.body)['data']);
      favAddress = userDetails['favouriteLocations']['data'];
      sosData = userDetails['sos']['data'];

      if (mapType == '') {
        mapType = userDetails['map_type'];
      }
      if (userDetails['bannerImage']['data'].toString().startsWith('{')) {
        banners.clear();
        banners.add(userDetails['bannerImage']['data']);
      } else {
        banners = userDetails['bannerImage']['data'];
      }
      if (userDetails['onTripRequest'] != null) {
        addressList.clear();
        if (userRequestData.isEmpty ||
            userRequestData['accepted_at'] !=
                userDetails['onTripRequest']['data']['accepted_at']) {
          polyline.clear();
          fmpoly.clear();
        } else if (userRequestData.isEmpty ||
            userRequestData['is_driver_arrived'] !=
                userDetails['onTripRequest']['data']['is_driver_arrived']) {
          polyline.clear();
          fmpoly.clear();
        }
        userRequestData = userDetails['onTripRequest']['data'];
        if (userRequestData['is_driver_arrived'] == 1 && polyline.isEmpty) {
          polyGot = true;
          getPolylines('', '', '', '');
          changeBound = true;
        }
        if (userRequestData['transport_type'] == 'taxi') {
          choosenTransportType = 0;
        } else {
          choosenTransportType = 1;
        }
        tripStops =
            userDetails['onTripRequest']['data']['requestStops']['data'];
        addressList.add(AddressList(
            id: '1',
            type: 'pickup',
            address: userRequestData['pick_address'],
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            name: userRequestData['pickup_poc_name'],
            pickup: true,
            number: userRequestData['pickup_poc_mobile'],
            instructions: userRequestData['pickup_poc_instruction']));
        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 2).toString(),
                type: 'drop',
                pickup: false,
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                name: tripStops[i]['poc_name'],
                number: tripStops[i]['poc_mobile'],
                instructions: tripStops[i]['poc_instruction']));
          }
        } else if (userDetails['onTripRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              pickup: false,
              address: userRequestData['drop_address'],
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              name: userRequestData['drop_poc_name'],
              number: userRequestData['drop_poc_mobile'],
              instructions: userRequestData['drop_poc_instruction']));
        }
        if (userRequestData['accepted_at'] != null) {
          getCurrentMessages();
        }
        if (userRequestData.isNotEmpty) {
          if (rideStreamUpdate == null ||
              rideStreamUpdate?.isPaused == true ||
              rideStreamStart == null ||
              rideStreamStart?.isPaused == true) {
            streamRide();
          }
        } else {
          if (rideStreamUpdate != null ||
              rideStreamUpdate?.isPaused == false ||
              rideStreamStart != null ||
              rideStreamStart?.isPaused == false) {
            rideStreamUpdate?.cancel();
            rideStreamUpdate = null;
            rideStreamStart?.cancel();
            rideStreamStart = null;
          }
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else if (userDetails['metaRequest'] != null) {
        addressList.clear();
        userRequestData = userDetails['metaRequest']['data'];
        tripStops = userDetails['metaRequest']['data']['requestStops']['data'];
        addressList.add(AddressList(
            id: '1',
            type: 'pickup',
            address: userRequestData['pick_address'],
            pickup: true,
            latlng: LatLng(
                userRequestData['pick_lat'], userRequestData['pick_lng']),
            name: userRequestData['pickup_poc_name'],
            number: userRequestData['pickup_poc_mobile'],
            instructions: userRequestData['pickup_poc_instruction']));

        if (tripStops.isNotEmpty) {
          for (var i = 0; i < tripStops.length; i++) {
            addressList.add(AddressList(
                id: (i + 2).toString(),
                type: 'drop',
                pickup: false,
                address: tripStops[i]['address'],
                latlng:
                    LatLng(tripStops[i]['latitude'], tripStops[i]['longitude']),
                name: tripStops[i]['poc_name'],
                number: tripStops[i]['poc_mobile'],
                instructions: tripStops[i]['poc_instruction']));
          }
        } else if (userDetails['metaRequest']['data']['is_rental'] != true &&
            userRequestData['drop_lat'] != null) {
          addressList.add(AddressList(
              id: '2',
              type: 'drop',
              address: userRequestData['drop_address'],
              pickup: false,
              latlng: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              name: userRequestData['drop_poc_name'],
              number: userRequestData['drop_poc_mobile'],
              instructions: userRequestData['drop_poc_instruction']));
        }
        if (polyline.isEmpty) {
          polyGot = true;
          getPolylines('', '', '', '');
          changeBound = true;
        }

        if (userRequestData['transport_type'] == 'taxi') {
          choosenTransportType = 0;
        } else {
          choosenTransportType = 1;
        }

        if (requestStreamStart == null ||
            requestStreamStart?.isPaused == true ||
            requestStreamEnd == null ||
            requestStreamEnd?.isPaused == true) {
          streamRequest();
        }
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      } else {
        chatList.clear();
        if (userRequestData.isNotEmpty) {
          polyline.clear();
          fmpoly.clear();
        }
        userRequestData = {};

        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        rideStreamUpdate?.cancel();
        rideStreamStart?.cancel();
        requestStreamEnd = null;
        requestStreamStart = null;
        rideStreamUpdate = null;
        rideStreamStart = null;
        valueNotifierHome.incrementNotifier();
        valueNotifierBook.incrementNotifier();
      }
      if (userDetails['active'] == false) {
        isActive = 'false';
      } else {
        isActive = 'true';
      }
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e, st) {
    print('SocketExceptionSocketExceptionSocketExceptionSocketException $e');
    print('SocketExceptionSocketExceptionSocketExceptionSocketException $st');
    rethrow;
    if (e is SocketException) {
      internet = false;
    }
  }
  print('resultresultresult $result');
  return result;
}

class BearerClass {
  final String type;
  final String token;

  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingChat {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingKey {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingLogin {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();
ValueNotifyingChat valueNotifierChat = ValueNotifyingChat();
ValueNotifyingKey valueNotifierKey = ValueNotifyingKey();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();
ValueNotifyingLogin valueNotifierLogin = ValueNotifyingLogin();
ValueNotifyingTimer valueNotifierTimer = ValueNotifyingTimer();

class ValueNotifyingTimer {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

//sound
AudioCache audioPlayer = AudioCache();
AudioPlayer audioPlayers = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

geoCoding(double lat, double lng) async {
  print('====== geoCoding =====');
  dynamic result;
  try {
    var value =
        await GeocodingPlatform.instance?.placemarkFromCoordinates(lat, lng);

    if (value != null) {
      result =
          '${((value[0].street == value[0].country) || (value[0].street == value[0].thoroughfare)) ? '' : value[0].street} ${value[0].thoroughfare} ${(value[0].subLocality == value[0].locality) ? '' : value[0].subLocality} ${value[0].locality} ${value[0].administrativeArea} ${value[0].country} ${value[0].postalCode}';
    } else {
      result = '';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//lang
getlangid() async {
  print('====== getlangid =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-my-lang'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bearerToken[0].token}',
            },
            body: jsonEncode({"lang": choosenLanguage}));
    // body: {
    //   'lang': choosenLanguage,
    // });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//get address auto fill data
List storedAutoAddress = [];
List addAutoFill = [];

pl.FlutterGooglePlacesSdk place = pl.FlutterGooglePlacesSdk(mapkey);

getAutocomplete(input, sessionToken, lat, lng) async {
  print('====== getAutocomplete =====');
  try {
    addAutoFill.clear();
    if (true || mapType == 'google') {
      var result = await place.findAutocompletePredictions(
        input,
        countries:
            (userDetails['enable_country_restrict_on_map'].toString() == '1' &&
                    userDetails['country_code'] != null)
                ? [userDetails['country_code']]
                : null,
        // origin: pl.LatLng(lat: center.latitude, lng: center.longitude),
      );
      for (var element in result.predictions) {
        addAutoFill.add({
          'place': element.placeId,
          'description': element.fullText,
          'secondary': (element.secondaryText == '')
              ? element.primaryText
              : element.secondaryText,
          'lat': '',
          'lon': ''
        });
      }
      pref.setString('autoAddress', jsonEncode(storedAutoAddress).toString());
    } else {
      var result = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$input&format=json'));
      print('resultresultresult ${result.body}');
      print('resultresultresult ${result.statusCode}');
      for (var element in jsonDecode(result.body)) {
        addAutoFill.add({
          'place': element['place_id'],
          'description': element['display_name'],
          'secondary': '',
          'lat': element['lat'],
          'lon': element['lon']
        });
      }
    }
    valueNotifierHome.incrementNotifier();
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//geocodeing location

geoCodingForLatLng(place, secondary) async {
  print('====== geoCodingForLatLng =====');
  try {
    // ignore: prefer_typing_uninitialized_variables
    var locs;
    var response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$place&key=$mapkey'));
    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['results'][0]['geometry']['location'];
      locs = LatLng(val['lat'], val['lng']);
    } else {
      debugPrint(response.body);
    }
    return locs;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//pickup drop address list

class AddressList {
  String address;
  LatLng latlng;
  String id;
  dynamic type;
  dynamic name;
  dynamic number;
  dynamic instructions;
  bool pickup;

  AddressList(
      {required this.id,
      required this.address,
      required this.latlng,
      required this.pickup,
      this.type,
      this.name,
      this.number,
      this.instructions});

  toJson() {}
}

//get polylines
String polyString = '';
List<LatLng> polyList = [];

getPolylines(plat, plng, dlat, dlng) async {
  print('====== getPolylines =====');
  polyString = '';
  polyList.clear();
  String pickLat = '';
  String pickLng = '';
  String dropLat = '';
  String dropLng = '';

  if (plat == '' && dlat == '') {
    if (userRequestData.isEmpty ||
        userRequestData['poly_line'] == null ||
        userRequestData['poly_line'] == '') {
      for (var i = 1; i < addressList.length; i++) {
        // Null safety checks for coordinates
        pickLat = addressList[i - 1].latlng.latitude?.toString() ?? '';
        pickLng = addressList[i - 1].latlng.longitude?.toString() ?? '';
        dropLat = addressList[i].latlng.latitude?.toString() ?? '';
        dropLng = addressList[i].latlng.longitude?.toString() ?? '';

        // Skip if any coordinate is empty
        if (pickLat.isEmpty || pickLng.isEmpty || dropLat.isEmpty || dropLng.isEmpty) {
          continue;
        }

        try {
          var value = await http.get(
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            Uri.parse(
                '${url}api/v1/request/get-directions?pick_lat=$pickLat&pick_lng=$pickLng&drop_lat=$dropLat&drop_lng=$dropLng'),
          );
          if (value.statusCode == 200) {
            var response = jsonDecode(value.body);
            var steps = response['points'];

            // Add null check for steps
            if (steps != null) {
              if (i == 1) {
                polyString = steps;
              } else {
                polyString = '${polyString}poly$steps';
              }
              decodeEncodedPolyline(steps);
            } else {
              print('Warning: Received null points from API for coordinates: $pickLat,$pickLng to $dropLat,$dropLng');
            }
          } else {
            print('Error: API returned status code ${value.statusCode}');
          }
        } catch (e) {
          print('Error in getPolylines: $e');
          if (e is SocketException) {
            internet = false;
          }
        }
      }
    } else {
      List poly = userRequestData['poly_line'].toString().split('poly');
      for (var i = 0; i < poly.length; i++) {
        if (poly[i].isNotEmpty) {
          decodeEncodedPolyline(poly[i]);
        }
      }
    }
  } else {
    try {
      // Null safety checks for direct coordinates
      if (plat.isEmpty || plng.isEmpty || dlat.isEmpty || dlng.isEmpty) {
        print('Error: Invalid coordinates provided');
        return polyList;
      }

      var value = await http.get(
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        Uri.parse(
            '${url}api/v1/request/get-directions?pick_lat=$plat&pick_lng=$plng&drop_lat=$dlat&drop_lng=$dlng'),
      );
      if (value.statusCode == 200) {
        var response = jsonDecode(value.body);
        var steps = response['points'];

        if (steps != null) {
          decodeEncodedPolyline(steps);
        } else {
          print('Warning: Received null points from API');
        }
      } else {
        print('Error: API returned status code ${value.statusCode}');
      }
    } catch (e) {
      print('Error in getPolylines: $e');
      if (e is SocketException) {
        internet = false;
      }
    }
  }
  polyGot = false;
  return polyList;
}

//polyline decode

Set<Polyline> polyline = {};

List<PointLatLng> decodeEncodedPolyline(String encoded) {
  print('====== decodeEncodedPolyline =====');
  List<PointLatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  polyline.clear();

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    polyList.add(p);
  }

  polyline.add(
    Polyline(
        polylineId: const PolylineId('1'),
        color: Colors.blue,
        visible: true,
        width: 4,
        points: polyList),
  );
  valueNotifierBook.incrementNotifier();
  return poly;
}

class PointLatLng {
  /// Creates a geographical location specified in degrees [latitude] and
  /// [longitude].
  ///
  const PointLatLng(double latitude, double longitude)
      // ignore: unnecessary_null_comparison
      : assert(latitude != null),
        // ignore: unnecessary_null_comparison
        assert(longitude != null),
        // ignore: unnecessary_this, prefer_initializing_formals
        this.latitude = latitude,
        // ignore: unnecessary_this, prefer_initializing_formals
        this.longitude = longitude;

  /// The latitude in degrees.
  final double latitude;

  /// The longitude in degrees
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}

//get goods list
List goodsTypeList = [];

getGoodsList() async {
  print('====== getGoodsList =====');
  dynamic result;
  goodsTypeList.clear();
  try {
    var response = await http.get(Uri.parse('${url}api/v1/common/goods-types'));
    if (response.statusCode == 200) {
      goodsTypeList = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//drop stops list
List<DropStops> dropStopList = <DropStops>[];

class DropStops {
  String order;
  double latitude;
  double longitude;
  String? pocName;
  String? pocNumber;
  dynamic pocInstruction;
  String address;

  DropStops(
      {required this.order,
      required this.latitude,
      required this.longitude,
      this.pocName,
      this.pocNumber,
      this.pocInstruction,
      required this.address});

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'poc_name': pocName,
        'poc_mobile': pocNumber,
        'poc_instruction': pocInstruction,
        'address': address,
      };
}

List etaDetails = [];

//eta request

etaRequest({transport, required int index}) async {
  print('====== etaRequest ===== index => $index');
  etaDetails.clear();
  dynamic result;

  try {
    // Validate data before constructing payload
    if (addressList.isEmpty ||
        addressList.where((element) => element.type == 'pickup').isEmpty) {
      print('Invalid addressList: Pickup location is missing');
      return false;
    }

    // Construct payload with null checks
    final payload = (addressList
                .where((element) => element.type == 'drop')
                .isNotEmpty &&
            dropStopList.isEmpty)
        ? {
            'pick_lat': userRequestData.isNotEmpty
                ? userRequestData['pick_lat']?.toString() ?? '0.0'
                : addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude
                    .toString(),
            'pick_lng': userRequestData.isNotEmpty
                ? userRequestData['pick_lng']?.toString() ?? '0.0'
                : addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude
                    .toString(),
            'drop_lat': userRequestData.isNotEmpty
                ? userRequestData['drop_lat']?.toString() ?? '0.0'
                : addressList
                    .lastWhere((e) => e.type == 'drop')
                    .latlng
                    .latitude
                    .toString(),
            'drop_lng': userRequestData.isNotEmpty
                ? userRequestData['drop_lng']?.toString() ?? '0.0'
                : addressList
                    .lastWhere((e) => e.type == 'drop')
                    .latlng
                    .longitude
                    .toString(),
            'ride_type': 1,
            'transport_type':
                transport ?? (choosenTransportType == 0 ? 'taxi' : 'delivery'),
          }
        : (dropStopList.isNotEmpty &&
                addressList
                    .where((element) => element.type == 'drop')
                    .isNotEmpty)
            ? {
                'pick_lat': userRequestData.isNotEmpty
                    ? userRequestData['pick_lat']?.toString() ?? '0.0'
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude
                        .toString(),
                'pick_lng': userRequestData.isNotEmpty
                    ? userRequestData['pick_lng']?.toString() ?? '0.0'
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude
                        .toString(),
                'drop_lat': userRequestData.isNotEmpty
                    ? userRequestData['drop_lat']?.toString() ?? '0.0'
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude
                        .toString(),
                'drop_lng': userRequestData.isNotEmpty
                    ? userRequestData['drop_lng']?.toString() ?? '0.0'
                    : addressList
                        .lastWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude
                        .toString(),
                'stops': jsonEncode(dropStopList),
                'ride_type': 1,
                'transport_type':
                    choosenTransportType == 0 ? 'taxi' : 'delivery',
              }
            : {
                'pick_lat': userRequestData.isNotEmpty
                    ? userRequestData['pick_lat']?.toString() ?? '0.0'
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude
                        .toString(),
                'pick_lng': userRequestData.isNotEmpty
                    ? userRequestData['pick_lng']?.toString() ?? '0.0'
                    : addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude
                        .toString(),
                'ride_type': 1,
                'transport_type':
                    choosenTransportType == 0 ? 'taxi' : 'delivery',
              };

    print('Request Payload: $payload');

    // Send request
    var response = await http.post(
      Uri.parse('${url}api/v1/request/eta'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    // Handle response
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      etaDetails = responseData['data'] ?? [];
      choosenVehicle =
          etaDetails.indexWhere((element) => element['is_default'] == true);
      result = true;
      valueNotifierBook.incrementNotifier();
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 500) {
      print('Server Error: ${response.body}');
      result = false;
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] ==
          "service not available with this location") {
        serviceNotAvailable = true;
      }
      result = false;
    }

    print('resultresultresultresultresultresultresult $result');
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
    return false;
  }
}

etaRequestWithPromo() async {
  print('====== etaRequestWithPromo =====');
  dynamic result;
  // etaDetails.clear();
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/eta'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: (addressList
                    .where((element) => element.type == 'drop')
                    .isNotEmpty &&
                dropStopList.isEmpty)
            ? jsonEncode({
                'pick_lat': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .latitude,
                'pick_lng': addressList
                    .firstWhere((e) => e.type == 'pickup')
                    .latlng
                    .longitude,
                'drop_lat': addressList
                    .firstWhere((e) => e.type == 'drop')
                    .latlng
                    .latitude,
                'drop_lng': addressList
                    .firstWhere((e) => e.type == 'drop')
                    .latlng
                    .longitude,
                'ride_type': 1,
                'promo_code': promoCode,
                'transport_type':
                    (choosenTransportType == 0) ? 'taxi' : 'delivery'
              })
            : (dropStopList.isNotEmpty &&
                    addressList
                        .where((element) => element.type == 'drop')
                        .isNotEmpty)
                ? jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude,
                    'drop_lat': addressList
                        .firstWhere((e) => e.type == 'drop')
                        .latlng
                        .latitude,
                    'drop_lng': addressList
                        .firstWhere((e) => e.type == 'drop')
                        .latlng
                        .longitude,
                    'stops': jsonEncode(dropStopList),
                    'ride_type': 1,
                    'promo_code': promoCode,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery'
                  })
                : jsonEncode({
                    'pick_lat': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .latitude,
                    'pick_lng': addressList
                        .firstWhere((e) => e.type == 'pickup')
                        .latlng
                        .longitude,
                    'ride_type': 1,
                    'promo_code': promoCode,
                    'transport_type':
                        (choosenTransportType == 0) ? 'taxi' : 'delivery'
                  }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      print('etaDetailsetaDetailsetaDetails => ${etaDetails}');
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      // promoCode = '';
      couponerror = true;
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//rental eta request

rentalEta() async {
  print('====== rentalEta =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/list-packages'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'pick_lat': (userRequestData.isNotEmpty)
                  ? userRequestData['pick_lat']
                  : addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .latitude,
              'pick_lng': (userRequestData.isNotEmpty)
                  ? userRequestData['pick_lng']
                  : addressList
                      .firstWhere((e) => e.type == 'pickup')
                      .latlng
                      .longitude,
              'transport_type':
                  (choosenTransportType == 0) ? 'taxi' : 'delivery'
            }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      choosenVehicle = 0;
      result = true;
      valueNotifierBook.incrementNotifier();
      // printWrapped('rental eta ' + response.body);
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = false;
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

bool couponerror = false;

rentalRequestWithPromo() async {
  print('====== rentalRequestWithPromo =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/request/list-packages'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude,
          'pick_lng': addressList
              .firstWhere((e) => e.type == 'pickup')
              .latlng
              .longitude,
          'ride_type': 1,
          'promo_code': promoCode,
          'transport_type': (choosenTransportType == 0) ? 'taxi' : 'delivery'
        }));

    if (response.statusCode == 200) {
      etaDetails = jsonDecode(response.body)['data'];
      rentalOption = etaDetails[0]['typesWithPrice']['data'];
      rentalChoosenOption = 0;
      promoCode = '';
      promoStatus = 1;
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      promoStatus = 2;
      couponerror = true;
      // promoCode = '';
      valueNotifierBook.incrementNotifier();

      result = false;
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//calculate distance

calculateDistance(lat1, lon1, lat2, lon2) {
  print('====== calculateDistance =====');
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  var val = (12742 * asin(sqrt(a))) * 1000;
  return val;
}

Map<String, dynamic> userRequestData = {};

//create request
String tripError = '';

createRequest(value, api) async {
  print('====== createRequest =====');
  waitingTime = 0;
  dynamic result;
  try {
    var response = await http.post(Uri.parse('$url$api'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: value);
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripError = jsonDecode(response.body)['message'].toString();
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//create request

createRequestLater(val, api) async {
  print('====== createRequestLater =====');
  dynamic result;
  waitingTime = 0;
  try {
    var response = await http.post(Uri.parse('$url$api'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: val);
    if (response.statusCode == 200) {
      result = 'success';
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//create request with promo code

createRequestLaterPromo() async {
  print('====== createRequestLaterPromo =====');
  dynamic result;
  waitingTime = 0;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'drop_lat':
              addressList.firstWhere((e) => e.id == 'drop').latlng.latitude,
          'drop_lng':
              addressList.firstWhere((e) => e.id == 'drop').latlng.longitude,
          'vehicle_type': etaDetails[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (etaDetails[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (etaDetails[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'drop_address': addressList.firstWhere((e) => e.id == 'drop').address,
          'promocode_id': etaDetails[choosenVehicle]['promocode_id'],
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': etaDetails[choosenVehicle]['total']
        }));
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }

  return result;
}

//create rental request

createRentalRequest() async {
  print('====== createRentalRequest =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';

      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

createRentalRequestWithPromo() async {
  print('====== createRentalRequestWithPromo =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      userRequestData = jsonDecode(response.body)['data'];
      streamRequest();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

createRentalRequestLater() async {
  print('====== createRentalRequestLater =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id']
        }));
    if (response.statusCode == 200) {
      result = 'success';
      streamRequest();
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

createRentalRequestLaterPromo() async {
  print('====== createRentalRequestLaterPromo =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/create'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pick_lat':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.latitude,
          'pick_lng':
              addressList.firstWhere((e) => e.id == 'pickup').latlng.longitude,
          'vehicle_type': rentalOption[choosenVehicle]['zone_type_id'],
          'ride_type': 1,
          'payment_opt': (rentalOption[choosenVehicle]['payment_type']
                      .toString()
                      .split(',')
                      .toList()[payingVia] ==
                  'card')
              ? 0
              : (rentalOption[choosenVehicle]['payment_type']
                          .toString()
                          .split(',')
                          .toList()[payingVia] ==
                      'cash')
                  ? 1
                  : 2,
          'pick_address':
              addressList.firstWhere((e) => e.id == 'pickup').address,
          'promocode_id': rentalOption[choosenVehicle]['promocode_id'],
          'trip_start_time': choosenDateTime.toString().substring(0, 19),
          'is_later': true,
          'request_eta_amount': rentalOption[choosenVehicle]['fare_amount'],
          'rental_pack_id': etaDetails[rentalChoosenOption]['id'],
        }));
    if (response.statusCode == 200) {
      myMarkers.clear();
      streamRequest();
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      if (jsonDecode(response.body)['message'] == 'no drivers available') {
        noDriverFound = true;
      } else {
        debugPrint(response.body);
        tripReqError = true;
      }

      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }

  return result;
}

List<RequestCreate> createRequestList = <RequestCreate>[];

class RequestCreate {
  dynamic pickLat;
  dynamic pickLng;
  dynamic dropLat;
  dynamic dropLng;
  dynamic vehicleType;
  dynamic rideType;
  dynamic paymentOpt;
  dynamic pickAddress;
  dynamic dropAddress;
  dynamic promoCodeId;

  RequestCreate(
      {this.pickLat,
      this.pickLng,
      this.dropLat,
      this.dropLng,
      this.vehicleType,
      this.rideType,
      this.paymentOpt,
      this.pickAddress,
      this.dropAddress,
      this.promoCodeId});

  Map<String, dynamic> toJson() => {
        'pick_lat': pickLat,
        'pick_lng': pickLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'vehicle_type': vehicleType,
        'ride_type': rideType,
        'payment_opt': paymentOpt,
        'pick_address': pickAddress,
        'drop_address': dropAddress,
        'promocode_id': promoCodeId
      };
}

//user cancel request

cancelRequest() async {
  print('====== cancelRequest =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': userRequestData['id']}));
    if (response.statusCode == 200) {
      userCancelled = true;
      if (userRequestData['is_bid_ride'] == 1) {
        FirebaseDatabase.instance
            .ref('bid-meta/${userRequestData["id"]}')
            .remove();
      }
      // FirebaseDatabase.instance
      //     .ref('requests')
      //     .child(userRequestData['id'])
      //     .update({'cancelled_by_user': true});
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

cancelLaterRequest(val) async {
  print('====== cancelLaterRequest =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'request_id': val}));
    if (response.statusCode == 200) {
      userRequestData = {};
      if (requestStreamStart?.isPaused == false ||
          requestStreamEnd?.isPaused == false) {
        requestStreamStart?.cancel();
        requestStreamEnd?.cancel();
        requestStreamStart = null;
        requestStreamEnd = null;
      }
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//user cancel request with reason

cancelRequestWithReason(reason) async {
  print('====== cancelRequestWithReason =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/cancel'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'request_id': userRequestData['id'], 'reason': reason}));
    if (response.statusCode == 200) {
      cancelRequestByUser = true;
      // FirebaseDatabase.instance
      //     .ref('requests/${userRequestData['id']}')
      //     .update({'cancelled_by_user': true});
      userRequestData = {};
      if (rideStreamUpdate?.isPaused == false ||
          rideStreamStart?.isPaused == false) {
        rideStreamUpdate?.cancel();
        rideStreamUpdate = null;
        rideStreamStart?.cancel();
        rideStreamStart = null;
      }
      await getUserDetails();
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//making call to user

makingPhoneCall(phnumber) async {
  print('====== makingPhoneCall =====');
  var mobileCall = 'tel:$phnumber';
  // ignore: deprecated_member_use
  if (await canLaunch(mobileCall)) {
    // ignore: deprecated_member_use
    await launch(mobileCall);
  } else {
    throw 'Could not launch $mobileCall';
  }
}

//cancellation reason
List cancelReasonsList = [];

cancelReason(reason) async {
  print('====== cancelReason =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
          '${url}api/v1/common/cancallation/reasons?arrived=$reason&transport_type=${userRequestData['transport_type']}'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      cancelReasonsList = jsonDecode(response.body)['data'];
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

List<CancelReasonJson> cancelJson = <CancelReasonJson>[];

class CancelReasonJson {
  dynamic requestId;
  dynamic reason;

  CancelReasonJson({this.requestId, this.reason});

  Map<String, dynamic> toJson() {
    return {'request_id': requestId, 'reason': reason};
  }
}

//add user rating

userRating() async {
  print('====== userRating =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/rating'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'request_id': userRequestData['id'],
          'rating': review,
          'comment': feedback
        }));
    if (response.statusCode == 200) {
      ismulitipleride = false;
      await getUserDetails();
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//class for realtime database driver data

class NearByDriver {
  double bearing;
  String g;
  String id;
  List l;
  String updatedAt;

  NearByDriver(
      {required this.bearing,
      required this.g,
      required this.id,
      required this.l,
      required this.updatedAt});

  factory NearByDriver.fromJson(Map<String, dynamic> json) {
    return NearByDriver(
        id: json['id'],
        bearing: json['bearing'],
        g: json['g'],
        l: json['l'],
        updatedAt: json['updated_at']);
  }
}

//add favourites location

addFavLocation(lat, lng, add, name) async {
  print('====== addFavLocation =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/user/add-favourite-location'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'pick_lat': lat,
          'pick_lng': lng,
          'pick_address': add,
          'address_name': name
        }));
    if (response.statusCode == 200) {
      result = true;
      await getUserDetails();
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//sos data
List sosData = [];

getSosData(lat, lng) async {
  print('====== getSosData =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/sos/list/$lat/$lng'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      sosData = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//sos admin notification

notifyAdmin() async {
  print('====== notifyAdmin =====');
  var db = FirebaseDatabase.instance.ref();
  try {
    await db.child('SOS/${userRequestData['id']}').update({
      "is_driver": "0",
      "is_user": "1",
      "req_id": userRequestData['id'],
      "serv_loc_id": userRequestData['service_location_id'],
      "updated_at": ServerValue.timestamp
    });
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
  return true;
}

//get current ride messages

List chatList = [];

getCurrentMessages() async {
  print('====== getCurrentMessages =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/chat-history/${userRequestData['id']}'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        if (chatList.where((element) => element['from_type'] == 2).length !=
            jsonDecode(response.body)['data']
                .where((element) => element['from_type'] == 2)
                .length) {}
        chatList = jsonDecode(response.body)['data'];
        valueNotifierBook.incrementNotifier();
      }
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//send chat

sendMessage(chat) async {
  print('====== sendMessage =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/request/send'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body:
            jsonEncode({'request_id': userRequestData['id'], 'message': chat}));
    if (response.statusCode == 200) {
      await getCurrentMessages();
      FirebaseDatabase.instance
          .ref('requests/${userRequestData['id']}')
          .update({'message_by_user': chatList.length});
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

//message seen

messageSeen() async {
  print('====== messageSeen =====');
  var response = await http.post(Uri.parse('${url}api/v1/request/seen'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'request_id': userRequestData['id']}));
  if (response.statusCode == 200) {
    getCurrentMessages();
  } else {
    debugPrint(response.body);
  }
}

//admin chat

dynamic chatStream;
String unSeenChatCount = '0';

streamAdminchat() async {
  print('====== streamAdminchat =====');
  chatStream = FirebaseDatabase.instance
      .ref()
      .child(
          'chats/${(adminChatList.length > 2) ? userDetails['chat_id'] : chatid}')
      .onValue
      .listen((event) async {
    var value =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(event.snapshot.value)));
    if (value['to_id'].toString() == userDetails['id'].toString()) {
      adminChatList.add(jsonDecode(jsonEncode(event.snapshot.value)));
    }
    value.clear();
    if (adminChatList.isNotEmpty) {
      unSeenChatCount =
          adminChatList[adminChatList.length - 1]['count'].toString();
      if (unSeenChatCount == 'null') {
        unSeenChatCount = '0';
      }
    }
    valueNotifierChat.incrementNotifier();
  });
}

//admin chat

List adminChatList = [];
dynamic isnewchat = 1;
dynamic chatid;

bool bannersShwon = false;

Future<void> showBanners(BuildContext context) async {
  print('====== showBanners =====');
  if (banners.isEmpty || bannersShwon) return;
  bannersShwon = true;

  showBannerDialog(context, banners[0]['image']);
}

void showBannerDialog(BuildContext context, String imageUrl) {
  print('====== showBannerDialog =====');
  showDialog(
    context: context,
    barrierDismissible: false,
    // Prevents dialog from being dismissed by tapping outside
    builder: (BuildContext context) {
      return WillPopScope(
        // Prevents dialog from being dismissed by back button
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ),
              SizedBox(height: 10),
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryAppColor,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

getadminCurrentMessages() async {
  print('====== getadminCurrentMessages =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/request/admin-chat-history'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json'
      },
    );
    if (response.statusCode == 200) {
      adminChatList.clear();
      isnewchat = jsonDecode(response.body)['data']['new_chat'];
      adminChatList = jsonDecode(response.body)['data']['chats'];
      if (adminChatList.isNotEmpty) {
        chatid = adminChatList[0]['chat_id'];
      }
      if (adminChatList.isNotEmpty && chatStream == null) {
        streamAdminchat();
      }
      unSeenChatCount = '0';
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

sendadminMessage(chat) async {
  print('====== sendadminMessage =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/send-message'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: (isnewchat == 1)
                ? jsonEncode({'new_chat': isnewchat, 'message': chat})
                : jsonEncode({
                    'new_chat': 0,
                    'message': chat,
                    'chat_id': chatid,
                  }));
    if (response.statusCode == 200) {
      chatid = jsonDecode(response.body)['data']['chat_id'];
      adminChatList.add({
        'chat_id': chatid,
        'message': jsonDecode(response.body)['data']['message'],
        'from_id': userDetails['id'],
        'to_id': jsonDecode(response.body)['data']['to_id'],
        'user_timezone': jsonDecode(response.body)['data']['user_timezone']
      });
      isnewchat = 0;
      if (adminChatList.isNotEmpty && chatStream == null) {
        streamAdminchat();
      }
      unSeenChatCount = '0';
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      result = 'failed';
      debugPrint(response.body);
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

adminmessageseen() async {
  print('====== adminmessageseen =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse(
          '${url}api/v1/request/update-notification-count?chat_id=$chatid'),
      headers: {
        'Authorization': 'Bearer ${bearerToken[0].token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      result = true;
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//add sos
void sortSosData() {
  sosData.sort((a, b) => (a['name'] ?? '')
      .toString()
      .toLowerCase()
      .compareTo((b['name'] ?? '').toString().toLowerCase()));
}

addSos(name, number) async {
  print('====== addSos =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/common/sos/store'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'name': name, 'number': number}));

    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
      sortSosData();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//remove sos

deleteSos(id) async {
  print('====== deleteSos =====');
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/common/sos/delete/$id'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//open url in browser

openBrowser(browseUrl) async {
  print('====== openBrowser =====');
  try {
    await launch(browseUrl);
  } catch (_) {}
}

//get faq
List faqData = [];
Map<String, dynamic> myFaqPage = {};

getFaqData(lat, lng) async {
  print('====== getFaqData =====');
  dynamic result;
  try {
    var response = await http
        .get(Uri.parse('${url}api/v1/common/faq/list/$lat/$lng'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      faqData = jsonDecode(response.body)['data'];
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

getFaqPages(id) async {
  print('====== getFaqPages =====');
  dynamic result;
  try {
    var response =
        await http.get(Uri.parse('${url}api/v1/common/faq/list/$id'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      var val = jsonDecode(response.body)['data'];
      val.forEach((element) {
        faqData.add(element);
      });
      myFaqPage = jsonDecode(response.body)['meta'];
      valueNotifierHome.incrementNotifier();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
    return result;
  }
}

//remove fav address

removeFavAddress(id) async {
  print('====== removeFavAddress =====');
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/user/delete-favourite-location/$id'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        });
    if (response.statusCode == 200) {
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//get user referral

Map<String, dynamic> myReferralCode = {};

getReferral() async {
  print('====== getReferral =====');
  dynamic result;
  try {
    var response =
        await http.get(Uri.parse('${url}api/v1/get/referral'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      result = 'success';
      myReferralCode = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//user logout

userLogout() async {
  print('====== userLogout =====');
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/logout'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//request history
List myHistory = [];
Map<String, dynamic> myHistoryPage = {};

String historyFiltter = 'is_completed=1';

getHistory() async {
  print('====== getHistory =====');
  dynamic result;
  try {
    // ignore: prefer_typing_uninitialized_variables
    var response;
    if (historyFiltter == '') {
      response = await http.get(
          Uri.parse('${url}api/v1/request/history?on_trip=0'),
          headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    } else {
      response = await http.get(
          Uri.parse('${url}api/v1/request/history?$historyFiltter'),
          headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    }
    if (response.statusCode == 200) {
      myHistory = jsonDecode(response.body)['data'];
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    myHistory.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getHistoryPages(id) async {
  print('====== getHistoryPages =====');
  dynamic result;

  try {
    var response = await http.get(Uri.parse('${url}api/v1/request/history?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        myHistory.add(element);
      });
      myHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    myHistory.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get wallet history

Map<String, dynamic> walletBalance = {};
Map<String, dynamic> paymentGateways = {};
List walletHistory = [];
Map<String, dynamic> walletPages = {};

getWalletHistory() async {
  print('====== getWalletHistory =====');
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/wallet/history'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      walletHistory = walletBalance['wallet_history']['data'];
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      paymentGateways = walletBalance['payment_gateways'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    walletHistory.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

getWalletHistoryPage(page) async {
  print('====== getWalletHistoryPage =====');
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/wallet/history?page=$page'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      walletBalance = jsonDecode(response.body);
      List list = walletBalance['wallet_history']['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        walletHistory.add(element);
      });
      walletPages = walletBalance['wallet_history']['meta']['pagination'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    walletHistory.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
      valueNotifierBook.incrementNotifier();
    }
  }
  return result;
}

//get client token for braintree

getClientToken() async {
  print('====== getClientToken =====');
  dynamic result;
  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/payment/client/token'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//stripe payment

Map<String, dynamic> stripeToken = {};

getStripePayment(money) async {
  print('====== getStripePayment =====');
  dynamic results;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/payment/stripe/intent'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({'amount': money}));
    if (response.statusCode == 200) {
      results = 'success';
      stripeToken = jsonDecode(response.body)['data'];
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      results = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return results;
}

//stripe add money

addMoneyStripe(amount, nonce) async {
  print('====== addMoneyStripe =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/stripe/add/money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//stripe pay money

payMoneyStripe(nonce) async {
  print('====== payMoneyStripe =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/stripe/make-payment-for-ride'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'request_id': userRequestData['id'], 'payment_id': nonce}));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//paystack payment
Map<String, dynamic> paystackCode = {};

getPaystackPayment(body) async {
  print('====== getPaystackPayment =====');
  dynamic results;
  paystackCode.clear();
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/payment/paystack/initialize'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: body);
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == false) {
        results = jsonDecode(response.body)['message'];
      } else {
        results = 'success';
        paystackCode = jsonDecode(response.body)['data'];
      }
    } else if (response.statusCode == 401) {
      results = 'logout';
    } else {
      debugPrint(response.body);
      results = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      results = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return results;
}

addMoneyPaystack(amount, nonce) async {
  print('====== addMoneyPaystack =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/paystack/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      paystackCode.clear();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//flutterwave

addMoneyFlutterwave(amount, nonce) async {
  print('====== addMoneyFlutterwave =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/flutter-wave/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//razorpay

addMoneyRazorpay(amount, nonce) async {
  print('====== addMoneyRazorpay =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/razerpay/add-money'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(
            {'amount': amount, 'payment_nonce': nonce, 'payment_id': nonce}));
    if (response.statusCode == 200) {
      await getWalletHistory();
      await getUserDetails();
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//cashfree

Map<String, dynamic> cftToken = {};

getCfToken(money, currency) async {
  print('====== getCfToken =====');
  cftToken.clear();
  cfSuccessList.clear();
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/cashfree/generate-cftoken'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'order_amount': money, 'order_currency': currency}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['status'] == 'OK') {
        cftToken = jsonDecode(response.body);
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

Map<String, dynamic> cfSuccessList = {};

cashFreePaymentSuccess() async {
  print('====== cashFreePaymentSuccess =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/cashfree/add-money-to-wallet-webhooks'),
        headers: {
          'Authorization': 'Bearer ${bearerToken[0].token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'orderId': cfSuccessList['orderId'],
          'orderAmount': cfSuccessList['orderAmount'],
          'referenceId': cfSuccessList['referenceId'],
          'txStatus': cfSuccessList['txStatus'],
          'paymentMode': cfSuccessList['paymentMode'],
          'txMsg': cfSuccessList['txMsg'],
          'txTime': cfSuccessList['txTime'],
          'signature': cfSuccessList['signature']
        }));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
        await getWalletHistory();
        await getUserDetails();
      } else {
        debugPrint(response.body);
        result = 'failure';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//edit user profile

Future<Uint8List> loadAssetAsBytes(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List();
}

updateProfile(name, email, usergender, phone) async {
  print('====== updateProfile =====');
  dynamic result;
  try {
    print('Phone number before sending: $phone'); // Debug phone number

    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ${bearerToken[0].token}'});

    if (profileImageFile != null) {
      if (profileImageFile.startsWith('assets/')) {
        // Handle asset file
        Uint8List fileBytes = await loadAssetAsBytes(profileImageFile);
        response.files.add(http.MultipartFile.fromBytes(
          'profile_picture',
          fileBytes,
        ));
      } else {
        // Handle local file
        response.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          profileImageFile,
        ));
      }
    }

    // Send the phone number as-is (without adding a country code)
    response.fields['email'] = email;
    response.fields['name'] = name;
    response.fields['mobile'] = phone; // Send the phone number as provided
    response.fields['gender'] = (gender == 'male')
        ? 'male'
        : (gender == 'female')
            ? 'female'
            : 'others';

    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);

    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

updateProfileWithoutImage(name, email, usergender) async {
  print('====== updateProfileWithoutImage =====');
  dynamic result;
  try {
    var response = http.MultipartRequest(
      'POST',
      Uri.parse('${url}api/v1/user/profile'),
    );
    response.headers
        .addAll({'Authorization': 'Bearer ${bearerToken[0].token}'});
    response.fields['email'] = email;
    response.fields['name'] = name;
    response.fields['gender'] = (gender == 'male')
        ? 'male'
        : (gender == 'female')
            ? 'female'
            : 'others';
    var request = await response.send();
    var respon = await http.Response.fromStream(request);
    final val = jsonDecode(respon.body);
    if (request.statusCode == 200) {
      result = 'success';
      if (val['success'] == true) {
        await getUserDetails();
      }
    } else if (request.statusCode == 401) {
      result = 'logout';
    } else if (request.statusCode == 422) {
      debugPrint(respon.body);
      var error = jsonDecode(respon.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(val);
      result = jsonDecode(respon.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//internet true
internetTrue() {
  print('====== internetTrue =====');
  internet = true;
  valueNotifierHome.incrementNotifier();
}

//make complaint

List generalComplaintList = [];

getGeneralComplaint(type) async {
  print('====== getGeneralComplaint =====');
  dynamic result;
  try {
    var response = await http.get(
      Uri.parse('${url}api/v1/common/complaint-titles?complaint_type=$type'),
      headers: {'Authorization': 'Bearer ${bearerToken[0].token}'},
    );
    if (response.statusCode == 200) {
      generalComplaintList = jsonDecode(response.body)['data'];
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

makeGeneralComplaint(complaintDesc) async {
  print('====== makeGeneralComplaint =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

makeRequestComplaint() async {
  print('====== makeRequestComplaint =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/common/make-complaint'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'complaint_title_id': generalComplaintList[complaintType]['id'],
              'description': complaintDesc,
              'request_id': myHistory[selectedHistory]['id']
            }));
    if (response.statusCode == 200) {
      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

//requestStream
StreamSubscription<DatabaseEvent>? requestStreamStart;
StreamSubscription<DatabaseEvent>? requestStreamEnd;
bool userCancelled = false;

streamRequest() {
  print('====== streamRequest =====');
  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;

  requestStreamStart = FirebaseDatabase.instance
      .ref('request-meta')
      .child(userRequestData['id'])
      .onChildRemoved
      .handleError((onError) {
    requestStreamStart?.cancel();
  }).listen((event) async {
    ismulitipleride = true;
    getUserDetails(id: userRequestData['id']);
    requestStreamEnd?.cancel();
    requestStreamStart?.cancel();
  });
}

StreamSubscription<DatabaseEvent>? rideStreamStart;

StreamSubscription<DatabaseEvent>? rideStreamUpdate;

streamRide() {
  print('====== streamRide =====');
  waitingTime = 0;
  requestStreamEnd?.cancel();
  requestStreamStart?.cancel();
  rideStreamUpdate?.cancel();
  rideStreamStart?.cancel();
  requestStreamStart = null;
  requestStreamEnd = null;
  rideStreamUpdate = null;
  rideStreamStart = null;
  rideStreamUpdate = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildChanged
      .handleError((onError) {
    rideStreamUpdate?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'modified_by_driver') {
      ismulitipleride = true;
      getUserDetails(id: userRequestData['id']);
    } else if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      ismulitipleride = true;
      // getUserDetails(id: userRequestData['id']);
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'total_waiting_time') {
      var val = event.snapshot.value.toString();
      waitingTime = int.parse(val);
      valueNotifierBook.incrementNotifier();
    } else if (event.snapshot.key.toString() == 'is_accept') {
      getUserDetails(id: userRequestData['id']);
    }
  });

  rideStreamStart = FirebaseDatabase.instance
      .ref('requests/${userRequestData['id']}')
      .onChildAdded
      .handleError((onError) {
    rideStreamStart?.cancel();
  }).listen((DatabaseEvent event) async {
    if (event.snapshot.key.toString() == 'message_by_driver') {
      getCurrentMessages();
    } else if (event.snapshot.key.toString() == 'cancelled_by_driver') {
      requestCancelledByDriver = true;
      ismulitipleride = true;
      // getUserDetails(id: userRequestData['id']);
      getUserDetails();
    } else if (event.snapshot.key.toString() == 'modified_by_driver') {
      ismulitipleride = true;
      getUserDetails(id: userRequestData['id']);
    } else if (event.snapshot.key.toString() == 'total_waiting_time') {
      var val = event.snapshot.value.toString();
      waitingTime = int.parse(val);
      valueNotifierBook.incrementNotifier();
    } else if (event.snapshot.key.toString() == 'is_accept') {
      getUserDetails(id: userRequestData['id']);
    }
  });
}

userDelete() async {
  print('====== userDelete =====');
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/user/delete-user-account'), headers: {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      pref.remove('Bearer');

      result = 'success';
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];
      internet = false;
    }
  }
  return result;
}

//request notification
List notificationHistory = [];
Map<String, dynamic> notificationHistoryPage = {};

getnotificationHistory() async {
  print('====== getnotificationHistory =====');
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/get-notification'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      notificationHistory = jsonDecode(response.body)['data'];
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
    notificationHistory.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

getNotificationPages(id) async {
  print('====== getNotificationPages =====');
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/get-notification?$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      List list = jsonDecode(response.body)['data'];
      // ignore: avoid_function_literals_in_foreach_calls
      list.forEach((element) {
        notificationHistory.add(element);
      });
      notificationHistoryPage = jsonDecode(response.body)['meta'];
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

//delete notification
deleteNotification(id) async {
  print('====== deleteNotification =====');
  dynamic result;

  try {
    var response = await http.get(
        Uri.parse('${url}api/v1/notifications/delete-notification/$id'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});
    if (response.statusCode == 200) {
      result = 'success';
      valueNotifierHome.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierHome.incrementNotifier();
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierHome.incrementNotifier();
    }
  }
  return result;
}

sharewalletfun({mobile, role, amount}) async {
  print('====== sharewalletfun =====');
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/wallet/transfer-money-from-wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bearerToken[0].token}',
        },
        body: jsonEncode({'mobile': mobile, 'role': role, 'amount': amount}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}

sendOTPtoEmail(String email) async {
  print('====== sendOTPtoEmail =====');
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/send-mail-otp'), body: {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'Something went wrong';
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

emailVerify(String email, otpNumber) async {
  print('====== emailVerify =====');
  dynamic val;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/validate-email-otp'),
        body: {"email": email, "otp": otpNumber});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        val = 'success';
      } else {
        debugPrint(response.body);
        val = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      val = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      val = 'Something went wrong';
    }
    return val;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

paymentMethod(payment) async {
  print('====== paymentMethod =====');
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/request/user/payment-method'),
            headers: {
              'Authorization': 'Bearer ${bearerToken[0].token}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'request_id': userRequestData['id'],
              'payment_opt': (payment == 'card')
                  ? 0
                  : (payment == 'cash')
                      ? 1
                      : (payment == 'wallet')
                          ? 2
                          : 4
            }));
    if (response.statusCode == 200) {
      FirebaseDatabase.instance
          .ref('requests')
          .child(userRequestData['id'])
          .update({'modified_by_user': ServerValue.timestamp});
      ismulitipleride = true;

      await getUserDetails(id: userRequestData['id']);
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failed';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

String isemailmodule = '1';
bool isCheckFireBaseOTP = true;

getemailmodule() async {
  print('====== getemailmodule =====');
  dynamic res;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/common/modules'),
    );

    if (response.statusCode == 200) {
      isemailmodule = jsonDecode(response.body)['enable_email_otp'];
      isCheckFireBaseOTP = jsonDecode(response.body)['firebase_otp_enabled'];
      print('isCheckFireBaseOTPisCheckFireBaseOTP ${isCheckFireBaseOTP}');

      res = 'success';
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      res = languages[choosenLanguage]['no internet'];
    }
  }

  return res;
}

sendOTPtoMobile(String mobile, String countryCode) async {
  print('====== sendOTPtoMobile =====');
  dynamic result;
  try {
    print('sendOTPtoMobilesendOTPtoMobile ${mobile} $countryCode');

    var response = await http.post(Uri.parse('${url}api/v1/mobile-otp'),
        body: {'mobile': mobile, 'country_code': countryCode});

    print('responseresponse ${response.statusCode}');
    print('responseresponse ${response.body}');
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
    return result;
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
}

validateSmsOtp(String mobile, String otp) async {
  print('====== validateSmsOtp =====');
  dynamic result;
  try {
    print('phone => $mobile');
    print('otp => $otp');
    var response = await http.post(Uri.parse('${url}api/v1/validate-otp'),
        body: {'mobile': mobile, 'otp': otp});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

List outStationList = [];

outStationListFun() async {
  print('====== outStationListFun =====');
  dynamic result;
  try {
    final response = await http.get(
        Uri.parse('${url}api/v1/request/outstation_rides'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});

    if (response.statusCode == 200) {
      outStationList = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    outStationList.removeWhere((element) => element.isEmpty);
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      result = languages[choosenLanguage]['no internet'];

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }

  return result;
}

List loginImages = [];

getLandingImages() async {
  print('====== getLandingImages =====');
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];
      loginImages.clear();
      List _images = jsonDecode(response.body)['data']['onboarding']['data'];
      for (var element in _images) {
        if (element['screen'] == 'user') {
          loginImages.add(element);
        }
      }
      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    print('errrr $e');
    if (e is SocketException) {
      internet = false;
      result = languages[choosenLanguage]['no internet'];
    }
  }
  return result;
}
