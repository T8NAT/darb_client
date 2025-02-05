import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../language/languages.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'loading.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

dynamic package;

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  bool updateAvailable = false;
  bool _gifLoaded = false;
  dynamic _package;
  dynamic _version;
  bool _error = false;
  bool _isLoading = false;
  Widget? nextPage;

  @override
  void initState() {
    getLanguageDone();
    getemailmodule();
    getLandingImages();
    super.initState();
  }

  navigate1() {
    nextPage = BookingConfirmation();
  }

  naviagteridewithoutdestini() {
    nextPage = BookingConfirmation(type: 2);
  }

  naviagterental() {
    nextPage = BookingConfirmation(type: 1);
  }

  //navigate
  navigate() async {
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
      //invoice page of ride
      nextPage = Invoice();
    } else if (userDetails['metaRequest'] != null) {
      addressList.clear();
      userRequestData = userDetails['metaRequest']['data'];
      // selectedHistory = i;
      addressList.add(AddressList(
          id: '1',
          type: 'pickup',
          address: userRequestData['pick_address'],
          pickup: true,
          latlng:
              LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']),
          name: userDetails['name'],
          number: userDetails['mobile']));
      if (userRequestData['requestStops']['data'].isNotEmpty) {
        for (var i = 0;
            i < userRequestData['requestStops']['data'].length;
            i++) {
          addressList.add(AddressList(
              id: userRequestData['requestStops']['data'][i]['id'].toString(),
              type: 'drop',
              address: userRequestData['requestStops']['data'][i]['address'],
              latlng: LatLng(
                  userRequestData['requestStops']['data'][i]['latitude'],
                  userRequestData['requestStops']['data'][i]['longitude']),
              name: '',
              number: '',
              instructions: null,
              pickup: false));
        }
      }

      if (userRequestData['drop_address'] != null &&
          userRequestData['requestStops']['data'].isEmpty) {
        addressList.add(AddressList(
            id: '2',
            type: 'drop',
            pickup: false,
            address: userRequestData['drop_address'],
            latlng: LatLng(
                userRequestData['drop_lat'], userRequestData['drop_lng'])));
      }

      ismulitipleride = true;

      var val = await getUserDetails(id: userRequestData['id']);

      //login page
      if (val == true) {
        setState(() {
          _isLoading = false;
        });
        if (userRequestData['is_rental'] == true) {
          naviagterental();
        } else if (userRequestData['is_rental'] == false &&
            userRequestData['drop_address'] == null) {
          naviagteridewithoutdestini();
        } else {
          navigate1();
        }
      }
    } else {
      nextPage = Maps();
    }
  }

  getData() async {
    for (var i = 0; _error == true; i++) {
      await getLanguageDone();
    }
  }

//get language json and data saved in local (bearer token , choosen language) and find users current status
  getLanguageDone() async {
    _package = await PackageInfo.fromPlatform();
    try {
      if (platform == TargetPlatform.android) {
        _version = await FirebaseDatabase.instance
            .ref()
            .child('user_android_version')
            .get();
      } else {
        _version = await FirebaseDatabase.instance
            .ref()
            .child('user_ios_version')
            .get();
      }
      _error = false;
      if (_version.value != null) {
        var version = _version.value.toString().split('.');
        var package = _package.version.toString().split('.');

        for (var i = 0; i < version.length || i < package.length; i++) {
          if (i < version.length && i < package.length) {
            if (int.parse(package[i]) < int.parse(version[i])) {
              setState(() {
                updateAvailable = true;
              });
              break;
            } else if (int.parse(package[i]) > int.parse(version[i])) {
              setState(() {
                updateAvailable = false;
              });
              break;
            }
          } else if (i >= version.length && i < package.length) {
            setState(() {
              updateAvailable = false;
            });
            break;
          } else if (i < version.length && i >= package.length) {
            setState(() {
              updateAvailable = true;
            });
            break;
          }
        }
      }

      if (updateAvailable == false) {
        await getDetailsOfDevice();
        if (internet == true) {
          var val = await getLocalData();

          if (val == '3') {
            navigate();
          } else if (choosenLanguage == '') {
            nextPage = Languages();
          } else if (val == '2') {
            nextPage = Login();
          } else {
            nextPage = Languages();
          }
        } else {
          setState(() {});
        }
      } else {
        return;
      }

      if (_gifLoaded) {
        if (nextPage != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => nextPage!),
            (_) => true,
          );
        } else {
          Navigator.pushAndRemoveUntil(
              context, MaterialPageRoute(builder: (context) => LoadingPage()),
                (_) => true,
          );
        }
      }
    } catch (e) {
      if (internet == true) {
        if (_error == false) {
          setState(() {
            _error = true;
          });
          getData();
        }
      } else {
        setState(() {});
      }
    }
  }

  void onGifLoaded() {
    if (!_gifLoaded) {
      _gifLoaded = true;
      if (nextPage == null) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => nextPage!),
            (_) => true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            Image.asset(
              'assets/videos/splash.gif',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.fill,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == 145) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    onGifLoaded();
                  });
                }
                return child;
              },
            ),

            //update available

            (updateAvailable == true)
                ? Positioned(
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: media.width * 0.9,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: white,
                          ),
                          margin: EdgeInsets.all(media.width * 0.05),
                          padding: EdgeInsets.all(media.width * 0.05),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 100,
                              ),
                              MyText(
                                text: languages[choosenLanguage]
                                        ?['new_version_available'] ??
                                    'تحديث جديد متوفر',
                                size: media.width * sixteen,
                                fontweight: FontWeight.w600,
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              MyText(
                                text: languages[choosenLanguage]
                                        ?['update_message'] ??
                                    'هناك تحديث جديد في المتجر، يرجى تحديثه لاستخدام الميزات الجديدة',
                                size: media.width * fifteen,
                                textAlign: TextAlign.start,
                                fontweight: FontWeight.w500,
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Button(
                                onTap: () async {
                                  if (platform == TargetPlatform.android) {
                                    openBrowser(
                                        'https://play.google.com/store/apps/details?id=${_package.packageName}');
                                  } else {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    var response = await http.get(Uri.parse(
                                        'http://itunes.apple.com/lookup?bundleId=${_package.packageName}'));
                                    if (response.statusCode == 200) {
                                      openBrowser(
                                          jsonDecode(response.body)['results']
                                              [0]['trackViewUrl']);
                                    }

                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },
                                text: languages[choosenLanguage]?['update'] ??
                                    'تحديث',
                              )
                            ],
                          ),
                        ),
                      ],
                    ))
                : Container(),

            //loader
            (_isLoading == true && internet == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

            //no internet
            (internet == false)
                ? Positioned(
                    top: 0,
                    child: NoInternet(
                      onTap: () {
                        setState(() {
                          internetTrue();
                          getLanguageDone();
                        });
                      },
                    ))
                : Container(),
          ],
        ),
      ),
    );
  }
}
