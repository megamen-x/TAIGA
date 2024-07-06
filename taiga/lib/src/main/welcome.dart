// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../../main.dart';
import '../system/login.dart';
import '../system/reg.dart';


class WelcomeWidget extends StatefulWidget {
  WelcomeWidget({Key? key}) : super(key: key);

  @override
  State<WelcomeWidget> createState() => WelcomeState();
}

class WelcomeState extends State<WelcomeWidget> {

  WindowEffect effect = WindowEffect.disabled;

  void setWindowEffect(WindowEffect? value) {
    Window.setEffect(
      effect: value!,
    );
    setState(() => effect = value);
  }

  @override
  void initState() {
    super.initState();
    setWindowEffect(effect);
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 1600;
    double frame = MediaQuery.of(context).size.width / baseWidth;
    double fframe = frame * 0.97;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WindowBorder(
        color: Colors.transparent,
        width: 0,
        child: 
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF000000),
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF000000),
                borderRadius: BorderRadius.circular(0.0*fframe),
              ),
              // 2A4350
              padding: EdgeInsets.fromLTRB(20*fframe, 20*fframe, 20*fframe, 20*fframe),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // window-btns
                  Container(
                    height: 60*fframe,
                    decoration: BoxDecoration(
                      color: Color(0xFF2A4350),
                      borderRadius: BorderRadius.circular(15.0*fframe),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 180*fframe,
                          height: 60*fframe,
                          decoration: BoxDecoration(
                            color: Color(0xFF20333E),
                            borderRadius: BorderRadius.circular(15.0*fframe),
                          ),
                        ),
                        Container(
                          width: 180*fframe,
                          height: 60*fframe,
                          decoration: BoxDecoration(
                            color: Color(0xFF20333E),
                            borderRadius: BorderRadius.circular(15.0*fframe),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const <Widget>[
                              WindowButtons(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20*fframe,
                  ),
                  // main-frame
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF2A4350),
                        borderRadius: BorderRadius.circular(15.0*fframe),
                      ),
                      padding: EdgeInsets.fromLTRB(20*fframe, 40*fframe, 20*fframe, 40*fframe),
                      child: 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // left
                              Container(
                                width: 610*fframe,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // up
                                    Column(
                                      children: <Widget>[
                                        SizedBox(
                                          height: 30*fframe,
                                        ),
                                        Container(
                                          width: 350*fframe,
                                          height: 350*fframe,
                                          decoration: BoxDecoration (
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(300.0*fframe)
                                          ),
                                          child: Image.asset(
                                            'assets/images/system/taiga_round.jpg',
                                            fit: BoxFit.fitHeight,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30*fframe,
                                        ),
                                        Container(
                                          width: 385*fframe,
                                          height: 140*fframe,
                                          child: Column(
                                            children: [
                                              Text('TAIGA', 
                                                textAlign: TextAlign.center, 
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontFamily: 'Limelight',
                                                  fontSize: 80*fframe,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.0*fframe/frame,
                                                )
                                              ),
                                              Text('от megamen',
                                                textAlign: TextAlign.center, 
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontFamily: 'Inter',
                                                  fontSize: 24*fframe,
                                                  fontWeight: FontWeight.w300,
                                                  letterSpacing: 5*fframe/frame,
                                                  height: 1.3*fframe/frame,
                                                )
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text('Приложение для распознавания\nи регистрации животных',
                                      textAlign: TextAlign.center, 
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontFamily: 'Inter',
                                        fontSize: 26*fframe,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 2*fframe/frame,
                                        height: 1.3*fframe/frame,
                                      )
                                    )
                                  ],
                                ),
                              ),
                              // right
                              Container(
                                width: 830*fframe,
                                height: 545*fframe,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text('ГЕНЕРАЛЬНЫЕ ПАРТНЕРЫ ПРОЕКТА',
                                      textAlign: TextAlign.center, 
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontFamily: 'Oswald',
                                        fontSize: 50*fframe,
                                        fontWeight: FontWeight.w500,
                                        // wordSpacing: 105,
                                        letterSpacing: 5*fframe/frame,
                                        height: 1.3*fframe/frame,
                                      )
                                    ),
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 253*fframe,
                                              height: 240*fframe,
                                              child: Image.asset(
                                                'assets/images/system/min-pr.png',
                                                fit: BoxFit.fitHeight,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 30*fframe,
                                            ),
                                            Text('МИНИСТЕРСТВО ПРИРОДНЫХ\nРЕСУРСОВ И ЭКОЛОГИИ\nРОССИЙСКОЙ ФЕДЕРАЦИИ',
                                              textAlign: TextAlign.center, 
                                              style: TextStyle(
                                                color: Color(0xFFFFFFFF),
                                                fontFamily: 'Spectral',
                                                fontSize: 23*fframe,
                                                fontWeight: FontWeight.w500,
                                                height: 1.3*fframe/frame,
                                              )
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 30*fframe,
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              width: 235*fframe,
                                              height: 240*fframe,
                                              child: Image.asset(
                                                'assets/images/system/min-ek.png',
                                                fit: BoxFit.fitHeight,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 30*fframe,
                                            ),
                                            Text('МИНИСТЕРСТВО\nЭКОНОМИЧЕСКОГО РАЗВИТИЯ\nРОССИЙСКОЙ ФЕДЕРАЦИИ',
                                              textAlign: TextAlign.center, 
                                              style: TextStyle(
                                                color: Color(0xFFFFFFFF),
                                                fontFamily: 'Spectral',
                                                fontSize: 23*fframe,
                                                fontWeight: FontWeight.w500,
                                                height: 1.3*fframe/frame,
                                              )
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // btns
                          Container(
                            width: 450*fframe,
                            height: 60*fframe,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                // sign-in
                                Container(
                                  // width: 130*fframe,
                                  height: 55*fframe,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF9F8F6),
                                    borderRadius: BorderRadius.circular(15.0*fframe),
                                  ),
                                  child: MaterialButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>  LoginWidget(prevpage: WelcomeWidget()),
                                          transitionsBuilder: (_, animation, __, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          }
                                        )
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0*fframe),
                                    ),
                                    height: 55*fframe,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('ВОЙТИ В АККАУНТ', 
                                        textAlign: TextAlign.center, 
                                        style: TextStyle(
                                          color: Color(0xFF000000),
                                          fontFamily: 'Inter',
                                          fontSize: 26*fframe,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3*fframe/frame,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // sign-up
                                // Container(
                                //   // width: 130*fframe,
                                //   height: 55*fframe,
                                //   decoration: BoxDecoration(
                                //     color: Color(0xFFF9F8F6),
                                //     borderRadius: BorderRadius.circular(15.0*fframe),
                                //   ),
                                //   child: MaterialButton(
                                //     onPressed: () {
                                //       Navigator.push(
                                //         context,
                                //         PageRouteBuilder(
                                //           pageBuilder: (_, __, ___) =>  RegWidget(prevpage: WelcomeWidget()),
                                //           transitionsBuilder: (_, animation, __, child) {
                                //             return FadeTransition(
                                //               opacity: animation,
                                //               child: child,
                                //             );
                                //           }
                                //         )
                                //       );
                                //     },
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(15.0*fframe),
                                //     ),
                                //     height: 55*fframe,
                                //     child: Text('СОЗДАТЬ АККАУНТ', 
                                //       textAlign: TextAlign.center, 
                                //       style: TextStyle(
                                //         color: Color(0xFF000000),
                                //         fontFamily: 'Inter',
                                //         fontSize: 26*fframe,
                                //         fontWeight: FontWeight.w700,
                                //         height: 1.3*fframe/frame,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}