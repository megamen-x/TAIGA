// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, unused_import, no_logic_in_create_state, prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../../main.dart';
import '../main/team.dart';
import '../system/account.dart';
import 'images.dart';

List <String> files = [];
String filepath = '';

class ExtImagesWidget extends StatefulWidget {
  final dataList, fileargs, images, timeList, dataEmptyFlag, prevpage, userData;

  ExtImagesWidget({super.key, @required this.dataList, this.fileargs, this.images, this.timeList, this.dataEmptyFlag, this.prevpage, this.userData});

  @override
  State<ExtImagesWidget> createState() => ExtImagesState(dataList: dataList, fileargs: fileargs, imagesList: images, timeList: timeList, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData: userData);
}

class ExtImagesState extends State<ExtImagesWidget> {

  var dataList, fileargs, imagesList, timeList, dataEmptyFlag, prevpage, userData;
  ExtImagesState({ @required this.dataList, this.fileargs, this.imagesList, this.timeList, this.dataEmptyFlag, this.prevpage, this.userData});

  bool loadingFlag = false;
  bool dataClearFlag = false;
  bool buttonflag = false;

  var shortcall = ShortenFileName();

  List<String> myList = [
    'responce/deer_7.jpg',
    'responce/deer_10.jpg',
    'responce/deer_14.jpg',
    'responce/deer_18.jpg'
  ];

  

  String substring = 'deer.jpg';
  List<dynamic> matchingElements = [];
  int newindex = 0;
  List<dynamic> filteredList = [];

  void item() {
    List<String> tmp = fileargs[0].split(', ');
    filteredList = imagesList.where((element) {
      String fileName = element.split('/').last;
      return tmp.contains(fileName);
    }).toList();
  }
  List<String> filesList = [];


  @override
  void initState() {
    super.initState();
    item();
  }
  // Масштабируемость реализации active learning
  // void NewDataLabel(context,fileargs) {
  //   showDialog(
  //     context: context, 
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: const Color(0xFF224138),
  //         shadowColor: const Color.fromARGB(79, 34, 65, 56),
  //         title: Text('Дополнительная разметка', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 24,fontWeight: FontWeight.w500, height: 1.3,),),
  //         content: Container(
  //           height: 100,
  //           child: Column(
  //             children: [
  //               Text('Определите новый класс животных на фотографии', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 20,fontWeight: FontWeight.w400, height: 1.3,),),
  //               SizedBox(
  //                 height: 23,
  //               ),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Container(
  //                     height: 50, 
  //                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
  //                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.0),border: Border.all(color: const Color(0xFFFFFFFF), width: 1)),
  //                     child: MaterialButton(
  //                       onPressed: () {setState(() {fileargs[2] = 'Выброс';}); Navigator.pop(context);}, 
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0),),
  //                       child: const Text('Выброс', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 20,fontWeight: FontWeight.w500, height: 1.3,),),
  //                       ),
  //                   ),
  //                   Container(
  //                     height: 50, 
  //                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
  //                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.0),border: Border.all(color: const Color(0xFFFFFFFF), width: 1)),
  //                     child: MaterialButton(
  //                       onPressed: () {setState(() {fileargs[2] = 'Косуля - Capreolus';}); Navigator.pop(context);}, 
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0),),
  //                       child: const Text('Косуля', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 20,fontWeight: FontWeight.w500, height: 1.3,),),
  //                       ),
  //                   ),
  //                   Container(
  //                     height: 50, 
  //                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
  //                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.0),border: Border.all(color: const Color(0xFFFFFFFF), width: 1)),
  //                     child: MaterialButton(
  //                       onPressed: () {setState(() {fileargs[2] = 'Олень - Cervus';}); Navigator.pop(context);}, 
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0),),
  //                       child: const Text('Олень', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 20,fontWeight: FontWeight.w500, height: 1.3,),),
  //                       ),
  //                   ),
  //                   Container(
  //                     height: 50, 
  //                     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
  //                     decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.0),border: Border.all(color: const Color(0xFFFFFFFF), width: 1)),
  //                     child: MaterialButton(
  //                       onPressed: () {setState(() {fileargs[2] = 'Кабарга - Moschus';}); Navigator.pop(context);}, 
  //                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.0),),
  //                       child: const Text('Кабарга', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFFFFF),fontFamily: 'Inter',fontSize: 20,fontWeight: FontWeight.w500, height: 1.3,),),
  //                       ),
  //                   ),
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           IconButton(
  //             icon: const Icon(Icons.close),
  //             color: Colors.white,
  //             tooltip: 'Выйти из меню разметки',
  //             onPressed: () {Navigator.pop(context);},
  //           ),
  //         ],
  //       );
  //     }
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 1600;
    double frame = MediaQuery.of(context).size.width / baseWidth;
    double fframe = frame * 0.97;
    return Scaffold(
      body: WindowBorder(
        color: Colors.black,
        width: 1,
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
                borderRadius: BorderRadius.circular(15.0*fframe),
              ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            children: [
                              Text('TAIGA', 
                                textAlign: TextAlign.center, 
                                style: TextStyle(
                                  color: Color(0xFFffffff),
                                  fontFamily: 'Limelight',
                                  fontSize: 40*fframe,
                                  fontWeight: FontWeight.w400,
                                  height: 1.0*fframe/frame,
                                )
                              ),
                            ],
                          ),
                        ),
                        // menu
                        Container(
                          width: 205*fframe,
                          height: 60*fframe,
                          padding: EdgeInsets.symmetric(vertical: 0*fframe, horizontal: 15*fframe),
                          decoration: BoxDecoration(
                            color: Color(0xFF20333E),
                            borderRadius: BorderRadius.circular(15.0*fframe),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // camera
                              Container(
                                width: 50*fframe,
                                height: 50*fframe,
                                decoration: BoxDecoration (
                                    color: Color(0xFF2A4350),
                                    borderRadius: BorderRadius.circular(10.0*fframe),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    print(timeList);
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>  ImagesWidget(filesarr: dataList, images: imagesList, tmptimeList: timeList, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData),
                                        transitionsBuilder: (_, animation, __, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        }
                                      )
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.fromLTRB(0*frame, 0*frame, 0*frame, 0*frame),
                                    side: const BorderSide(color: Color(0xffF9F8F6), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0*fframe)),
                                  ),
                                  child: SizedBox(
                                    width: 40*fframe,
                                    height: 40*fframe,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/system/camera.svg',
                                        semanticsLabel: 'Camera'
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // team
                              Container(
                                width: 50*fframe,
                                height: 50*fframe,
                                decoration: BoxDecoration (
                                    color: Color(0xFF2A4350),
                                    borderRadius: BorderRadius.circular(10.0*fframe),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>  AccWidget(prevpage: prevpage, userData:userData),
                                        transitionsBuilder: (_, animation, __, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        }
                                      )
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.fromLTRB(0*frame, 0*frame, 0*frame, 0*frame),
                                    side: const BorderSide(color: Color(0xffF9F8F6), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0*fframe)),
                                  ),
                                  child: SizedBox(
                                    width: 45*fframe,
                                    height: 45*fframe,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/system/account.svg',
                                        semanticsLabel: 'Camera'
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // camera
                              Container(
                                width: 50*fframe,
                                height: 50*fframe,
                                decoration: BoxDecoration (
                                    color: Color(0xFF2A4350),
                                    borderRadius: BorderRadius.circular(10.0*fframe),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>  TeamWidget(prevpage: prevpage, userData:userData),
                                        transitionsBuilder: (_, animation, __, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        }
                                      )
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.fromLTRB(0*frame, 0*frame, 0*frame, 0*frame),
                                    side: const BorderSide(color: Color(0xffF9F8F6), width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0*fframe)),
                                  ),
                                  child: SizedBox(
                                    width: 45*fframe,
                                    height: 45*fframe,
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/system/team.svg',
                                        semanticsLabel: 'Camera'
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                      padding: EdgeInsets.fromLTRB(20*fframe, 20*fframe, 20*fframe, 20*fframe),
                      child: 
                      SingleChildScrollView(
                        child: Container(
                          height: 730*fframe,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // back
                              Container(
                                width: 50*fframe,
                                height: 50*fframe,
                                decoration: BoxDecoration (
                                    color: Color(0xFFF9F8F6),
                                    borderRadius: BorderRadius.circular(10.0*fframe),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    print(timeList);
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>  ImagesWidget(filesarr: dataList, images: imagesList, tmptimeList: timeList, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData, newLabelData: fileargs),
                                        transitionsBuilder: (_, animation, __, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        }
                                      )
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.fromLTRB(0*frame, 0*frame, 0*frame, 0*frame),
                                    side: const BorderSide(color: Color(0xffF9F8F6), width: 0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0*fframe)),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/images/system/arrowleft.svg',
                                      semanticsLabel: 'Camera'
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 5*fframe,
                              ),
                              // main
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(0*fframe, 0*fframe, 50*fframe, 0*fframe),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      // frame
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          //  text-input
                                          Container(
                                            width: 700*fframe,
                                            height: 700*fframe,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF20333E),
                                              borderRadius: BorderRadius.circular(15.0*fframe),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 15*fframe, vertical: 15*fframe),
                                            child: 
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                
                                                Container(
                                                  width: 660*fframe,
                                                  height: 660*fframe,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF2A4350),
                                                    borderRadius: BorderRadius.circular(12.0*fframe),
                                                  ),
                                                  child: 
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    // fileargs[0].split(', ').length
                                                    child: ListView.builder(
                                                      itemCount: fileargs[0].split(', ').length,
                                                      itemBuilder: (context, index) {
                                                        return 
                                                          Column(
                                                            children: [
                                                              Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: ClipRRect(
                                                                  borderRadius: BorderRadius.circular(15.0),
                                                                  child: Image.file(
                                                                    File(filteredList[index]),
                                                                    fit: BoxFit.contain,
                                                                    height: 420*frame,
                                                                    width: MediaQuery.of(context).size.width * 1,
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 10*fframe,
                                                              ),
                                                              Text(filteredList[index],
                                                                textAlign: TextAlign.start, 
                                                                style: TextStyle(
                                                                  color: Color(0xFFFFFFFF),
                                                                  fontFamily: 'Inter',
                                                                  fontSize: 20*fframe,
                                                                  fontWeight: FontWeight.w500,
                                                                  letterSpacing: 3*fframe/frame,
                                                                  height: 1.3*fframe/frame,
                                                                )
                                                              ),
                                                              SizedBox(
                                                                height: 40*fframe,
                                                              ),
                                                            ],
                                                          );
                                                      }
                                                    ),
                                                    // child: PageView.builder(
                                                    //   controller: _imageController,
                                                    //   scrollDirection: Axis.horizontal,
                                                    //   itemCount: 2,
                                                    //   itemBuilder: (context, index) {
                                                    //     return ClipRRect(
                                                    //       child:
                                                    //         Image.file(File(images[index]),
                                                    //           height: 420*frame,
                                                    //           width: MediaQuery.of(context).size.width * 1,
                                                    //           fit: BoxFit.contain,
                                                    //         ),
                                                    //     );
                                                    //   },
                                                    // ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 40*fframe,
                                          ),
                                          Container(
                                            width: 6*fframe,
                                            height: 620*fframe,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF1A95D7),
                                              borderRadius: BorderRadius.circular(15.0*fframe),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 40*fframe,
                                          ),
                                          // instructions
                                          Container(
                                            width: 600*fframe,
                                            height: 700*fframe,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF20333E),
                                              borderRadius: BorderRadius.circular(15.0*fframe),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 30*fframe, vertical: 20*fframe),
                                            child: 
                                            // file info
                                            Column(
                                              children: [
                                                Text('ДАННЫЕ О РЕГИСТРАЦИИ',
                                                  textAlign: TextAlign.start, 
                                                  style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontFamily: 'Oswald',
                                                    fontSize: 30*fframe,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 5*fframe/frame,
                                                    height: 1.3*fframe/frame,
                                                  )
                                                ),
                                                SizedBox(
                                                  height: 30*fframe,
                                                ),
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFFF9F8F6),
                                                        borderRadius: BorderRadius.circular(15.0*fframe),
                                                      ),
                                                      padding: EdgeInsets.symmetric(horizontal: 15*fframe, vertical: 30*fframe),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Названия: \n${fileargs[0].split('\n\n').join(', ')}',
                                                          //${shortcall(fileargs[0].split('\n\n'), 20)}
                                                            textAlign: TextAlign.start, 
                                                            style: TextStyle(
                                                              color: Color(0xFF000000), 
                                                              fontFamily: 'Inter',
                                                              fontSize: 18*fframe,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: 1*fframe/frame,
                                                              height: 1.7*fframe/frame,
                                                            )
                                                          ),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 10*fframe,
                                                          ),
                                                          Text('Класс: \n${fileargs[1].split('\n\n').join(', ')}',
                                                            textAlign: TextAlign.start, 
                                                            style: TextStyle(
                                                              color: Color(0xFF000000),
                                                              fontFamily: 'Inter',
                                                              fontSize: 18*fframe,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: 1*fframe/frame,
                                                              height: 1.7*fframe/frame,
                                                            )
                                                          ),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 10*fframe,
                                                          ),
                                                          Text('Время: \n${fileargs[2].split('\n\n').join(', ')}',
                                                            textAlign: TextAlign.start, 
                                                            style: TextStyle(
                                                              color: Color(0xFF000000),
                                                              fontFamily: 'Inter',
                                                              fontSize: 18*fframe,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: 1*fframe/frame,
                                                              height: 1.7*fframe/frame,
                                                            )
                                                          ),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            height: 10*fframe,
                                                          ),
                                                          Text('Количество: \n${fileargs[3].split('\n\n').join(', ')}',
                                                            textAlign: TextAlign.start, 
                                                            style: TextStyle(
                                                              color: Color(0xFF000000),
                                                              fontFamily: 'Inter',
                                                              fontSize: 18*fframe,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: 1*fframe/frame,
                                                              height: 1.7*fframe/frame,
                                                            )
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 30*fframe,
                                                    ),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Padding(
                                                            padding: const EdgeInsets.all(5.0),
                                                            child: Text('Отметьте ниже - наличие ошибки\nв предсказании: ',
                                                              textAlign: TextAlign.start, 
                                                              style: TextStyle(
                                                                color: Color(0xFFEDEDED),
                                                                fontFamily: 'Inter',
                                                                fontSize: 24*fframe,
                                                                fontWeight: FontWeight.w400,
                                                                letterSpacing: 1*fframe/frame,
                                                                height: 1.3*fframe/frame,
                                                              )
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 20*fframe,
                                                          ),
                                                          Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Container(
                                                                height: 55*fframe,
                                                                padding: EdgeInsets.symmetric(horizontal: 0*fframe, vertical: 0*fframe),
                                                                decoration: BoxDecoration(
                                                                  // color: Color(0xFFF9F8F6),
                                                                  borderRadius: BorderRadius.circular(15.0*fframe),
                                                                  border: Border.all(color: Color(0xFF1A95D7), width: 3*fframe)
                                                                ),
                                                                child: MaterialButton(
                                                                  onPressed: () {
                                                                    // NewDataLabel(context, fileargs);
                                                                  },
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(12.0*fframe),
                                                                  ),
                                                                  height: 55*fframe,
                                                                  child: Text('Ошибка классификатора', 
                                                                    textAlign: TextAlign.center, 
                                                                    style: TextStyle(
                                                                      color: Color(0xFFF9F8F6),
                                                                      fontFamily: 'Inter',
                                                                      fontSize: 24*fframe,
                                                                      fontWeight: FontWeight.w500,
                                                                      height: 1.3*fframe/frame,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
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
        
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
