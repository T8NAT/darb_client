import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user/translations/translation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/nointernet.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

dynamic profileImageFile;

class _EditProfileState extends State<EditProfile> {
  ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  String _error = '';
  bool _pickImage = false;
  String _permission = '';
  bool showToast = false;
  TextEditingController name = TextEditingController();
  TextEditingController lastname = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController mobilenum = TextEditingController();
  TextEditingController usergender = TextEditingController();
  bool islastname = false;

//get gallery permission
  getGalleryPermission() async {
    dynamic status;
    if (platform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }

        /// use [Permissions.storage.status]
      } else {
        status = await Permission.photos.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.photos.request();
        }
      }
    } else {
      status = await Permission.photos.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.photos.request();
      }
    }
    return status;
  }

  bool isEdit = false;

  showToastFunc() {
    setState(() {
      showToast = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showToast = false;
        });
      }
    });
  }

  navigateLogout() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false);
    });
  }

//get camera permission
  getCameraPermission() async {
    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }
    return status;
  }

//pick image from gallery
  pickImageFromGallery() async {
    var permission = await getGalleryPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      setState(() {
        profileImageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noPhotos';
      });
    }
  }

//pick image from camera
  pickImageFromCamera() async {
    var permission = await getCameraPermission();
    if (permission == PermissionStatus.granted) {
      final pickedFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      setState(() {
        profileImageFile = pickedFile?.path;
        _pickImage = false;
      });
    } else {
      setState(() {
        _permission = 'noCamera';
      });
    }
  }

  @override
  void initState() {
    _error = '';
    profileImageFile = null;
    isEdit = false;
    name.text = userDetails['name'].toString().split(' ')[0];
    lastname.text = (userDetails['name'].toString().split(' ').length > 1)
        ? userDetails['name'].toString().split(' ')[1]
        : '';
    mobilenum.text = userDetails['mobile'];
    email.text = userDetails['email'];
    usergender.text = (userDetails['gender'] == null)
        ? languages[choosenLanguage]['text_not_specified']
        : userDetails['gender'];
    setState(() {});
    super.initState();
  }

  pop() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Scaffold(
        backgroundColor: white,
        body: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        media.width * 0.05,
                        media.width * 0.05,
                        media.width * 0.05,
                        media.width * 0.05),
                    decoration: BoxDecoration(color: white, boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          offset: const Offset(0, 1),
                          blurRadius: 8)
                    ]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                            onTap: () {
                              Navigator.pop(context, true);
                            },
                            child:
                                Icon(Icons.arrow_back_ios, color: textColor)),
                        SizedBox(
                          width: media.width * 0.6,
                          child: MyText(
                            textAlign: TextAlign.center,
                            text: (!isEdit)
                                ? languages[choosenLanguage]
                                    ['text_personal_info']
                                : languages[choosenLanguage]
                                    ['text_editprofile'],
                            size: media.width * twenty,
                            maxLines: 1,
                            fontweight: FontWeight.w600,
                          ),
                        ),
                        (isEdit)
                            ? Container()
                            : Tapper(
                                onTap: () {
                                  Future.delayed(
                                      const Duration(milliseconds: 500), () {
                                    setState(() {
                                      isEdit = true;
                                    });
                                  });
                                },
                                rippleColor: hintColor.withOpacity(0.1),
                                child: Container(
                                  alignment: Alignment.center,
                                  width: media.width * 0.15,
                                  child: MyText(
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    text: languages[choosenLanguage]
                                        ['text_edit'],
                                    // color: buttonColor,
                                    color: primaryAppColor,
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w500,
                                  ),
                                ),
                              )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.02,
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      width: media.width * 1,
                      color: white,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(height: media.width * 0.05),
                                  InkWell(
                                    onTap: () {
                                      if (isEdit) {
                                        setState(() {
                                          _pickImage = true;
                                        });
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: media.width * 0.25,
                                          width: media.width * 0.25,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: white,
                                                image: (profileImageFile == null)
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                          userDetails[
                                                              'profile_picture'], // Fallback to backend image
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : DecorationImage(
                                                  image: profileImageFile.startsWith('assets/')
                                                      ? AssetImage(profileImageFile) as ImageProvider<Object> // Use AssetImage for assets
                                                      : FileImage(File(profileImageFile)), // Use FileImage for local files
                                                  fit: BoxFit.cover,
                                                ),
                                          ),
                                        ),
                                        if (isEdit)
                                          Positioned(
                                              right: media.width * 0.02,
                                              bottom: media.width * 0.02,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: media.width * 0.05,
                                                    width: media.width * 0.05,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xff898989)),
                                                    child: Icon(
                                                      Icons.edit,
                                                      color: white,
                                                      size: media.width * 0.04,
                                                    ),
                                                  ),
                                                ],
                                              )),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: media.width * 0.04,
                                  ),
                                  Row(
                                    children: [
                                      ProfileDetails(
                                        heading: languages[choosenLanguage]
                                            ['text_name'],
                                        controller: name,
                                        width: media.width * 0.9,
                                        readyonly: (isEdit) ? false : true,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  // if (!isEdit)
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_mob_num'],
                                    controller: mobilenum,
                                    readyonly: (isEdit) ? false : true,
                                  ),
                                  SizedBox(
                                    height: media.height * 0.02,
                                  ),
                                  ProfileDetails(
                                    heading: languages[choosenLanguage]
                                        ['text_email'],
                                    controller: email,
                                    readyonly: (isEdit) ? false : true,
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  (!isEdit)
                                      ? ProfileDetails(
                                          heading: languages[choosenLanguage]
                                              ['text_gender'],
                                          controller: usergender,
                                          readyonly: (isEdit) ? false : true,
                                        )
                                      : (userDetails['gender'] != null)
                                          ? Container()
                                          : SizedBox(
                                              width: media.width * 0.9,
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            ['text_gender'],
                                                        // 'Gender',
                                                        style:
                                                            GoogleFonts.almarai(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    underline,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                        maxLines: 1,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.025,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            usergender.text =
                                                                'male';
                                                          });
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.05,
                                                              width:
                                                                  media.width *
                                                                      0.05,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    width: 1.2,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              // decoration: BoxDecoration(
                                                              //     border: Border.all(
                                                              //         color: Colors
                                                              //             .black,
                                                              //         width:
                                                              //             1.2)),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: (usergender
                                                                          .text ==
                                                                      'male')
                                                                  ? Container(
                                                                      height: media
                                                                              .width *
                                                                          0.03,
                                                                      width: media
                                                                              .width *
                                                                          0.03,
                                                                      decoration: const BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          color:
                                                                              Colors.black),
                                                                    )
                                                                  // ? Center(
                                                                  //     child:
                                                                  //         Icon(
                                                                  //     Icons
                                                                  //         .done,
                                                                  //     size: media.width *
                                                                  //         0.04,
                                                                  //   ))
                                                                  : Container(),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.015,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.15,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_male'],
                                                                // 'Male',
                                                                style: GoogleFonts.almarai(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            usergender.text =
                                                                'female';
                                                          });
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              height:
                                                                  media.width *
                                                                      0.05,
                                                              width:
                                                                  media.width *
                                                                      0.05,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    width: 1.2,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              // decoration: BoxDecoration(
                                                              //     border: Border.all(
                                                              //         color: Colors
                                                              //             .black,
                                                              //         width:
                                                              //             1.2)),
                                                              child: (usergender
                                                                          .text ==
                                                                      'female')
                                                                  ? Container(
                                                                      height: media
                                                                              .width *
                                                                          0.03,
                                                                      width: media
                                                                              .width *
                                                                          0.03,
                                                                      decoration: const BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          color:
                                                                              Colors.black),
                                                                    )
                                                                  // ? Center(
                                                                  //     child:
                                                                  //         Icon(
                                                                  //     Icons
                                                                  //         .done,
                                                                  //     size: media.width *
                                                                  //         0.04,
                                                                  //   ))
                                                                  : Container(),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.015,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.15,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_female'],
                                                                // 'Female',
                                                                style: GoogleFonts.almarai(
                                                                    fontSize: media
                                                                            .width *
                                                                        fourteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                              ),
                                            )
                                ],
                              ),
                            ),
                          ),
                          if (_error != '')
                            Container(
                              padding: EdgeInsets.only(top: media.width * 0.02),
                              child: MyText(
                                text: _error,
                                size: media.width * twelve,
                                color: Colors.red,
                              ),
                            ),
                          if (isEdit)
                            Button(
                                onTap: () async {
                                  setState(() {
                                    _error = '';
                                  });

                                  String pattern =
                                      r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])*$";
                                  var remail = email.text.replaceAll(' ', '');
                                  RegExp regex = RegExp(pattern);
                                  if (regex.hasMatch(remail)) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    // ignore: prefer_typing_uninitialized_variables

                                    print('Original mobilenum.text FULL INFO: ${mobilenum.text}');
                                    print('Original mobilenum.text LENGTH: ${mobilenum.text.length}');

                                    String cleanedPhoneNumber = mobilenum.text.startsWith('+966')
                                        ? mobilenum.text.substring(4)  // Remove '+966'
                                        : mobilenum.text;
                                    print('Cleaned phone number: $cleanedPhoneNumber');
                                    mobilenum.text = cleanedPhoneNumber;
                                    print('Updated mobilenum.text: ${mobilenum.text}');
                                    var nav;
                                    if (userDetails['email'] == remail) {
                                      nav = await updateProfile(
                                          '${name.text} ${lastname.text}',
                                          remail,
                                          usergender.text,
                                          mobilenum.text
                                          // userDetails['mobile']
                                          );
                                      if (nav != 'success') {
                                        _error = nav.toString();
                                      } else {
                                        isEdit = false;
                                        _isLoading = false;
                                        showToastFunc();
                                      }
                                    } else {
                                      var result = await validateEmail(remail);
                                      if (result == 'success') {
                                        nav = await updateProfile(
                                            '${name.text} ${lastname.text}',
                                            remail,
                                            usergender.text,
                                            mobilenum.text
                                            // userDetails['mobile']
                                            );
                                        if (nav != 'success') {
                                          _error = nav.toString();
                                        } else {
                                          showToastFunc();
                                        }
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                          _error = result;
                                        });
                                      }

                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _error = languages[choosenLanguage]
                                          ['text_email_validation'];
                                    });
                                  }
                                },
                                text: languages[choosenLanguage]
                                    ['text_confirm']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (showToast == true)
                Positioned(
                    bottom: media.width * 0.05,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                          media.width * 0.05, 0, media.width * 0.05, 0),
                      width: media.width * 0.9,
                      padding: EdgeInsets.all(media.width * 0.03),
                      decoration: BoxDecoration(
                          color: white,
                          boxShadow: [boxshadow],
                          borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: MyText(
                        text: 'Profile Updated Successfully',
                        size: media.width * fourteen,
                        color: Colors.green,
                        fontweight: FontWeight.w500,
                      ),
                    )),

              //pick image popup
              (_pickImage == true)
                  ? Positioned(
                      bottom: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _pickImage = false;
                          });
                        },
                        child: Container(
                          height: media.height * 1,
                          width: media.width * 1,
                          color: Colors.transparent.withOpacity(0.6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.all(media.width * 0.05),
                                width: media.width * 1,
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(25),
                                        topRight: Radius.circular(25)),
                                    border: Border.all(
                                      color: borderLines,
                                      width: 1.2,
                                    ),
                                    color: white),
                                child: Column(
                                  children: [
                                    Container(
                                      height: media.width * 0.02,
                                      width: media.width * 0.15,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            media.width * 0.01),
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(
                                      height: media.width * 0.05,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                pickImageFromCamera();
                                              },
                                              child: Container(
                                                  height: media.width * 0.171,
                                                  width: media.width * 0.171,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Icon(
                                                    Icons.camera_alt_outlined,
                                                    size: media.width * 0.064,
                                                    color: textColor,
                                                  )),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.02,
                                            ),
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_camera'],
                                              size: media.width * ten,
                                              color: textColor.withOpacity(0.4),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                pickImageFromGallery();
                                              },
                                              child: Container(
                                                  height: media.width * 0.171,
                                                  width: media.width * 0.171,
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: borderLines,
                                                          width: 1.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12)),
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: media.width * 0.064,
                                                    color: textColor,
                                                  )),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.02,
                                            ),
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_gallery'],
                                              size: media.width * ten,
                                              color: textColor.withOpacity(0.4),
                                            )
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () {

                                            final pickedFile =
                                            'assets/images/default-profile-picture.jpeg';
                                            setState(() {
                                              profileImageFile = pickedFile;
                                              _pickImage = false;
                                            });
                                            },
                                          child: Column(
                                            children: [
                                              Container(
                                                height: media.width * 0.171,
                                                width: media.width * 0.171,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: borderLines,
                                                      width: 1.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  size: media.width * 0.064,
                                                  color: textColor,
                                                ),
                                              ),
                                              SizedBox(
                                                  height: media.width * 0.02),
                                              MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_remove'],
                                                size: media.width * ten,
                                                color:
                                                    textColor.withOpacity(0.4),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  : Container(),

              //permission denied popup
              (_permission != '')
                  ? Positioned(
                      child: Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: media.width * 0.9,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _permission = '';
                                      _pickImage = false;
                                    });
                                  },
                                  child: Container(
                                    height: media.width * 0.1,
                                    width: media.width * 0.1,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle, color: white),
                                    child: Icon(Icons.cancel_outlined,
                                        color: textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: media.width * 0.05,
                          ),
                          Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            width: media.width * 0.9,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: white,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 2.0,
                                      spreadRadius: 2.0,
                                      color: Colors.black.withOpacity(0.2))
                                ]),
                            child: Column(
                              children: [
                                SizedBox(
                                    width: media.width * 0.8,
                                    child: MyText(
                                      text: (_permission == 'noPhotos')
                                          ? languages[choosenLanguage]
                                              ['text_open_photos_setting']
                                          : languages[choosenLanguage]
                                              ['text_open_camera_setting'],
                                      size: media.width * sixteen,
                                      fontweight: FontWeight.w600,
                                    )),
                                SizedBox(height: media.width * 0.05),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                        onTap: () async {
                                          await openAppSettings();
                                        },
                                        child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_open_settings'],
                                          size: media.width * sixteen,
                                          fontweight: FontWeight.w600,
                                          color: buttonColor,
                                        )),
                                    InkWell(
                                        onTap: () async {
                                          (_permission == 'noCamera')
                                              ? pickImageFromCamera()
                                              : pickImageFromGallery();
                                          setState(() {
                                            _permission = '';
                                          });
                                        },
                                        child: MyText(
                                          text: languages[choosenLanguage]
                                              ['text_done'],
                                          size: media.width * sixteen,
                                          fontweight: FontWeight.w600,
                                          color: buttonColor,
                                        ))
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                  : Container(),
              //loader
              (_isLoading == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container(),

              //error
              (_error != '')
                  ? Positioned(
                      child: Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            width: media.width * 0.9,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: white),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: media.width * 0.8,
                                  child: MyText(
                                    text: _error.toString(),
                                    textAlign: TextAlign.center,
                                    size: media.width * sixteen,
                                    fontweight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                Button(
                                    onTap: () async {
                                      setState(() {
                                        _error = '';
                                      });
                                    },
                                    text: languages[choosenLanguage]['text_ok'])
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                  : Container(),

              //no internet
              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          setState(() {
                            internetTrue();
                          });
                        },
                      ))
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
