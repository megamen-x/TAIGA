// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, unused_import, no_logic_in_create_state, prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:mime/mime.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http_parser/http_parser.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../../main.dart';
import '../main/team.dart';
import '../system/account.dart';
import 'images_ext.dart';

List <String> files = [];


class ImagesWidget extends StatefulWidget {
  final filesarr, images, dataEmptyFlag, prevpage, userData, newLabelData;
  ImagesWidget({super.key, @required this.filesarr, this.images, this.dataEmptyFlag, this.prevpage, this.userData, this.newLabelData});

  @override
  State<ImagesWidget> createState() => ImagesState(filesarr: filesarr, images: images, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData: userData, newLabelData: newLabelData);
}

class ImagesState extends State<ImagesWidget> {

  var filesarr, images, dataEmptyFlag, prevpage, userData, newLabelData;
  ImagesState({ @required this.filesarr, this.images, this.dataEmptyFlag, this.prevpage, this.userData, this.newLabelData});

  bool loadingFlag = false;
  bool loadingFlag2 = false;
  bool dataClearFlag = false;
  bool isDragged = false;
  bool zipplot = false;

  var shortcall = ShortenFileName();

  ScrollController _singleChildScroll = new ScrollController();
  final ScrollController _small = ScrollController();

  String current = Directory.current.path;
  late Uri fileprovider = Uri.parse('file:///${'$current/responce'}');


  final List<XFile> _list = [];
  List<String> newfileargs = [];
  List<Map<String, dynamic>> jsonDataList = [];
  List<DataModel> dataList = [DataModel(column1: [' ',], column2: [' ',], column3: [' ',], column4: [' ',])];
  
  @override
  void initState() {
    showingTooltip = -1;
    dataList = filesarr;
    // DataModel.updateDataModel(dataList, newLabelData);
    jsonDataList = dataList.map((dataModel) => dataModel.toJson()).toList();
    super.initState();
    // print(jsonDataList);
  }

  String plotName = '';

  Future<void> uploadFile(context) async {
    setState(() {
      loadingFlag = true;
    });

    List<String>? pathFiles = [];
    for (var i = 0; i < _list.length; i++) {
      if (Platform.isWindows) {
        pathFiles.add(_list[i].path.replaceAll('\\', '/'));
      }
      if (Platform.isLinux) {
        pathFiles.add(_list[i].path);
      }
    }
    print(pathFiles);
    for (var i = 0; i < pathFiles.length; i++) {
      if (path.extension(pathFiles[i]) == '.zip') {
        uploadZip(context, pathFiles);
      }
      else if (path.extension(pathFiles[i]) == '.png' || path.extension(pathFiles[i]) == '.jpg' || path.extension(pathFiles[i]) == '.jpeg') {
        uploadImage(context, pathFiles);
      }
      else {
        debugPrint('blya(');
      }
    }
  }

  Future<void> uploadZip(context, pathFiles) async {

    setState(() {
      loadingFlag2 = true;
      plotName = ' ';
      zipplot = false;
    });

    if (pathFiles != null) {
      try {
        var  postUri = Uri.parse('http://127.0.0.1:8000/zip/');
        var request = http.MultipartRequest('POST', postUri);
        for (var i = 0; i < pathFiles.length; i++) {
          String? mediaType = lookupMimeType(pathFiles[i].split("/").last);
          request.files.add(await http.MultipartFile.fromPath('files', pathFiles[i], filename: pathFiles[i].split("/").last, contentType: mediaType != null ? MediaType.parse(mediaType) : null));
        }
        Map<String, String> userDataString = {
          "Authorization": "Token ${userData['auth_token']}"
        };
        request.headers.addAll(userDataString);
        var streamedResponse  = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        print(response.statusCode);
        if (response.statusCode == 200) {
          unzipFileFromResponse(response.bodyBytes, 'zip/');
          String path = '';
          if (Platform.isWindows || Platform.isLinux) path = "./responce/zip/data.txt";
          File dataFile = File(path);
          String dataString = dataFile.readAsStringSync();
          final responceMap = jsonDecode(dataString);
          final dataMap = jsonDecode(jsonEncode(responceMap["data"]));
          print(dataMap);
          setState(() {
            dataClearFlag = true;
            dataEmptyFlag = false;
            loadingFlag = false;
            loadingFlag2 = false;
            dataList = [];
            zipplot = false;
          });
          setState(() {
            var tmp = dataMap.length;
            for (var i = 0; i < tmp; i++) {
              DataModel newData = DataModel.fromJson(dataMap[i]);
              dataList.add(newData);
            }
            zipplot = true;
            // plotName = './responce/zip/deers_fig.jpeg';
          });

        }

      } on SocketException {
        setState(() {
          Sample.AlshowDialog(context, 'Нет соединения с сервером!', 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      } on HttpException {
        setState(() {
          Sample.AlshowDialog(context, "Не удалось найти метод post!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      } on FormatException {
        setState(() {
          Sample.AlshowDialog(context, "Неправильный формат ответа!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      }

    } else {
      setState(() {
        loadingFlag2 = false;
      });
    }
  }

  Future<void> uploadImage(context, pathFiles) async {
    setState(() {
      loadingFlag = true;
    });

    print(pathFiles);
    if (pathFiles != null) {
      try {    
        var  postUri = Uri.parse('http://127.0.0.1:8000/files/');
        var request = http.MultipartRequest('POST', postUri);
        for (var i = 0; i < pathFiles.length; i++) {
          String? mediaType = lookupMimeType(pathFiles[i].split("/").last);
          request.files.add(await http.MultipartFile.fromPath('files', pathFiles[i], filename: pathFiles[i].split("/").last,  contentType: mediaType != null ? MediaType.parse(mediaType) : null,),);
        }
        Map<String, String> userDataString = {
          "Authorization": "Token ${userData['auth_token']}"
        };
        request.headers.addAll(userDataString);
        var streamedResponse  = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          unzipFileFromResponse(response.bodyBytes, 'images/');
          String path = '';
          if (Platform.isWindows || Platform.isLinux) path = "./responce/images/data.txt";
          File dataFile = File(path);
          String dataString = dataFile.readAsStringSync();
          final responceMap = jsonDecode(dataString);
          final dataMap = jsonDecode(jsonEncode(responceMap["data"]));
          setState(() {
            dataClearFlag = true;
            dataEmptyFlag = false;
            loadingFlag = false;
            dataList = [];
          });
          setState(() {
            var tmp = dataMap.length;
            for (var i = 0; i < tmp; i++) {
              DataModel newData = DataModel.fromJson(dataMap[i]);
              dataList.add(newData);
            }
          });
        }
        else {
          setState(() {
            loadingFlag = false;
          });
        }
      } on SocketException {
        setState(() {
          Sample.AlshowDialog(context, 'Нет соединения с сервером!', 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag = false;
        });
      } on HttpException {
        setState(() {
          Sample.AlshowDialog(context, "Не удалось найти метод post!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag = false;
        });
      } on FormatException {
        setState(() {
          Sample.AlshowDialog(context, "Неправильный формат ответа!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag = false;
        });
      }
    } else {
      setState(() {
        loadingFlag2 = false;
      });
    }
  }

  Future<void> uploadNewData(context) async {
    final json = jsonDataList;
    try {
      final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/active_learning/'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            "Authorization": "Token ${userData['auth_token']}"
          },
          body: jsonEncode(json),
      );
      // print(response.statusCode);
      if (response.statusCode == 200) {
        Sample.AlshowDialog(context, 'Обучение модели запущено', 'Обучение может занять продолжительное время');
      }
      Sample.AlshowDialog(context, 'Обучение модели запущено', 'Обучение может занять продолжительное время');
    } on SocketException {
        setState(() {
          Sample.AlshowDialog(context, 'Нет соединения с сервером!', 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      } on HttpException {
        setState(() {
          Sample.AlshowDialog(context, "Не удалось найти метод post!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      } on FormatException {
        setState(() {
          Sample.AlshowDialog(context, "Неправильный формат ответа!", 'Проверьте состояние сервера и попробуйте снова');
          loadingFlag2 = false;
        });
      }
  }

  Future<void> _fileProvider() async {
    if (!await launchUrl(fileprovider)) {
      throw Exception('Could not launch $fileprovider');
    }
  }

  Future<void> clearData() async {
    if (Platform.isWindows || Platform.isLinux) {
      images = [];
      dataList = [DataModel(column1: [' ',], column2: [' ',], column3: [' ',], column4: [' ',])];
      deleteFilesInFolder("./responce/images");
      deleteFilesInFolder("./responce/zip");
      deleteFilesInFolder("./responce/zip/images");
    }
    setState(() {
      _list.clear();
      dataEmptyFlag = false;
      zipplot = false;
      loadingFlag2 = false;
    });
  }

  // delete files in folder func
  Future<void> deleteFilesInFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  // unzip server responce
  Future<void> unzipFileFromResponse(List<int> responseBody, String path) async {
    final archive = ZipDecoder().decodeBytes(responseBody);
    images = [];
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        if (filename.contains('.jpg') || filename.contains('.JPG') || filename.contains('.jpeg') || filename.contains('.JPEG') || filename.contains('.png')|| filename.contains('.PNG') || filename.contains('.bmp')) {
          if (Platform.isWindows || Platform.isLinux) {
            File('responce/$path$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
            images.add('responce/$path$filename');
          }
        }
        else {
          if (Platform.isWindows || Platform.isLinux) {
            File('responce/$path$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
          }
        }
      } else {
        await Directory('responce/$path$filename').create(recursive: true);
      }
    }
  }
  
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
                              // back
                              Container(
                                width: 50*fframe,
                                height: 50*fframe,
                                decoration: BoxDecoration (
                                    color: Color(0xFF2A4350),
                                    borderRadius: BorderRadius.circular(10.0*fframe),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Navigator.push(
                                    //   context,
                                    //   PageRouteBuilder(
                                    //     pageBuilder: (_, __, ___) =>  VideosWidget(filesarr: filesarr, dataEmptyFlag: dataEmptyFlag, prevpage: ImagesWidget(filesarr: filesarr, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData), userData:userData),
                                    //     transitionsBuilder: (_, animation, __, child) {
                                    //       return FadeTransition(
                                    //         opacity: animation,
                                    //         child: child,
                                    //       );
                                    //     }
                                    //   )
                                    // );
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
                                        pageBuilder: (_, __, ___) =>  AccWidget(prevpage: ImagesWidget(filesarr: filesarr, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData), userData:userData),
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
                                        pageBuilder: (_, __, ___) =>  TeamWidget(prevpage: ImagesWidget(filesarr: filesarr, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData), userData:userData),
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
                      padding: EdgeInsets.fromLTRB(0*fframe, 20*fframe, 0*fframe, 20*fframe),
                      child: 
                      SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(60*fframe, 10*fframe, 60*fframe, 10*fframe),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // instructions
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          SizedBox(
                                            width: 400*fframe,
                                            child: Text('Выбор файлов',
                                              textAlign: TextAlign.start, 
                                              style: TextStyle(
                                                color: Color(0xFFFFFFFF),
                                                fontFamily: 'Oswald',
                                                fontSize: 30*fframe,
                                                fontWeight: FontWeight.w400,
                                                letterSpacing: 5*fframe/frame,
                                                height: 1.3*fframe/frame,
                                              )
                                            ),
                                          ),
                                          SizedBox(
                                            height: 15*fframe,
                                          ),
                                          DropTarget(
                                            onDragDone: (detail) async {
                                              setState(() {
                                                _list.addAll(detail.files);
                                              });
                                              debugPrint('onDragDone:');
                                              for (final file in detail.files) {
                                                debugPrint('  ${file.path} ${file.name}'
                                                    '  ${await file.lastModified()}'
                                                    '  ${await file.length()}'
                                                    '  ${file.mimeType}');
                                              }
                                            },
                                            onDragEntered: (detail) => setState(() => isDragged = true),
                                            onDragExited: (detail) => setState(() => isDragged = false),
                                            child: Container(
                                              width: 400*fframe,
                                              height: 200*fframe,
                                              decoration: BoxDecoration (
                                                  color: isDragged ? Color(0xFFD0E7F3) : Color(0xFFF9F8F6),
                                                  borderRadius: BorderRadius.circular(12.0*fframe)
                                              ),
                                              padding: EdgeInsets.symmetric(horizontal: 10*fframe, vertical: 15*fframe),
                                              child: 
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  if (_list.isEmpty)
                                                    Column(
                                                      children: [
                                                        Container(
                                                          width: 70*fframe,
                                                          height: 70*fframe,
                                                          child: SvgPicture.asset(
                                                            'assets/images/system/file.svg',
                                                            semanticsLabel: 'File'
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 300*fframe,  
                                                          padding: EdgeInsets.symmetric(horizontal: 10*fframe, vertical: 15*fframe),                                                            child: 
                                                          Center(
                                                            child: 
                                                            Text('Перетащите сюда ваши файлы',
                                                              textAlign: TextAlign.center, 
                                                              style: TextStyle(
                                                                color: Color(0xFF000000),
                                                                fontFamily: 'Inter',
                                                                fontSize: 24*fframe,
                                                                fontWeight: FontWeight.w400,
                                                                letterSpacing: 0,
                                                                height: 1.3*fframe/frame,
                                                              )
                                                            ),
                                                          )
                                                        ),
                                                      ],
                                                    )
                                                  else 
                                                  loadingFlag
                                                    ? const Center(child: SizedBox(width: 65, height: 65, child: CircularProgressIndicator(color: Color(0xFF437590) )))
                                                    : 
                                                  Container(
                                                    height: 170*fframe,
                                                    padding: EdgeInsets.symmetric(horizontal: 10*fframe, vertical: 10*fframe),
                                                    child: 
                                                    SingleChildScrollView(
                                                      controller: _small,
                                                      child: Stack(
                                                        alignment: Alignment.topCenter,
                                                        children: [
                                                          Container(
                                                            decoration: BoxDecoration (
                                                                color: Color(0xFF437590),
                                                                borderRadius: BorderRadius.circular(12.0*fframe)
                                                            ),
                                                            padding: EdgeInsets.symmetric(horizontal: 10*fframe, vertical: 10*fframe),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(Platform.isWindows ? _list.asMap().entries.map((e) => '${e.key + 1}. ${shortcall(e.value.path.split('\\').last, 20)}').join('\n') : _list.asMap().entries.map((e) => '${e.key + 1}. ${shortcall(e.value.path.split('/').last, 20)}').join('\n'),
                                                                  textAlign: TextAlign.start, 
                                                                  style: TextStyle(
                                                                    color: Color(0xFFEDEDED),
                                                                    fontFamily: 'Inter',
                                                                    fontSize: 18*fframe,
                                                                    fontWeight: FontWeight.w300,
                                                                    letterSpacing: 0,
                                                                    height: 1.5*fframe/frame,
                                                                  )
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ]
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 15*fframe,),
                                          SizedBox(
                                            width: 400*fframe,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: <Widget>[
                                                // submit
                                                Tooltip(
                                                  message: "Обработать файлы",
                                                  child: Container(
                                                    height: 65*fframe,
                                                    width: 65*fframe,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF437590),
                                                      borderRadius: BorderRadius.circular(15.0*fframe),
                                                    ),
                                                    child: MaterialButton(
                                                      onPressed: () {
                                                        uploadFile(context);
                                                      },
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15.0*fframe),
                                                      ),
                                                      height: 65*fframe,
                                                      child: 
                                                      loadingFlag
                                                      ? const Center(child: SizedBox(width: 35, height: 35, child: CircularProgressIndicator(color: Color(0xFFffffff) )))
                                                      : SvgPicture.asset(
                                                        'assets/images/system/done.svg',
                                                        semanticsLabel: 'Submit',
                                                        width: 45*fframe,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 20*fframe,),
                                                // clear
                                                Tooltip(
                                                  message: "Очистить выборку",
                                                  child: Container(
                                                    height: 65*fframe,
                                                    width: 65*fframe,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF437590),
                                                      borderRadius: BorderRadius.circular(15.0*fframe),
                                                    ),
                                                    child: MaterialButton(
                                                      onPressed: () {
                                                        loadingFlag = false;
                                                        clearData();
                                                        dataEmptyFlag = true;
                                                      },
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15.0*fframe),
                                                      ),
                                                      height: 65*fframe,
                                                      child: 
                                                      SvgPicture.asset(
                                                        'assets/images/system/trash.svg',
                                                        semanticsLabel: 'Trash',
                                                        width: 45*fframe,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 20*fframe,),
                                                // download
                                                Tooltip(
                                                  message: "Скачать файл предсказания",
                                                  child: Container(
                                                    height: 65*fframe,
                                                    width: 65*fframe,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF437590),
                                                      borderRadius: BorderRadius.circular(15.0*fframe),
                                                    ),
                                                    child: MaterialButton(
                                                      onPressed: () {
                                                        _fileProvider();
                                                      },
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15.0*fframe),
                                                      ),
                                                      height: 65*fframe,
                                                      child: 
                                                      SvgPicture.asset(
                                                        'assets/images/system/download.svg',
                                                        semanticsLabel: 'Download',
                                                        width: 45*fframe,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 20*fframe,),
                                                Tooltip(
                                                  message: "Дообучение модели",
                                                  child: Container(
                                                    height: 65*fframe,
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF437590),
                                                      borderRadius: BorderRadius.circular(15.0*fframe),
                                                    ),
                                                    child: MaterialButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          uploadNewData(context);
                                                        });
                                                      },
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15.0*fframe),
                                                      ),
                                                      height: 50*fframe,
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 5*fframe, vertical: 0*fframe),
                                                        child: Text('ACTIVE\nLEARNING', 
                                                          textAlign: TextAlign.center, 
                                                          style: TextStyle(
                                                            color: Color(0xFFF9F8F6),
                                                            fontFamily: 'Inter',
                                                            fontSize: 20*fframe,
                                                            fontWeight: FontWeight.w600,
                                                            height: 1.3*fframe/frame,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 22*fframe,),
                                          SizedBox(
                                            width: 400*fframe,
                                            child: Text('Как пользоваться?',
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
                                          ),
                                          SizedBox(
                                            height: 20*fframe,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFFFFFF),
                                              borderRadius: BorderRadius.circular(15.0*fframe),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 20*fframe, vertical: 25*fframe),
                                            width: 400*fframe,
                                            child: UnorderedList(const [
                                                "Загрузите ваши фото",
                                                "Дождитесь обработки",
                                                "Найдите интересующий объект в таблице",
                                                "Нажмите на объект для детальной информации",
                                                "Нажмите “Данные” - откроется папка с предсказаниями модели",
                                            ], frame, 20, Color(0xFF000000), FontWeight.w400),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 15*fframe,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 40*fframe,
                                  ),
                                  //  table
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        child: Text('Таблица предсказаний',
                                          textAlign: TextAlign.center, 
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontFamily: 'Oswald',
                                            fontSize: 30*fframe,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 5*fframe/frame,
                                            height: 1.3*fframe/frame,
                                          )
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10*fframe,
                                      ),
                                      Container(
                                        width: 1000*fframe,
                                        height: 310*fframe,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF437590),
                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                        ),
                                        child: 
                                        SingleChildScrollView(
                                          controller: _singleChildScroll,
                                          scrollDirection: Axis.vertical,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 20*fframe, vertical: 15*fframe),
                                            child: DataTable(
                                              dataRowMaxHeight: double.infinity,
                                              dataRowMinHeight: 65,
                                              dividerThickness: 2,
                                              showCheckboxColumn: false,
                                              sortAscending: true,
                                              columns: [
                                                DataColumn(label: 
                                                  Text('ФАЙЛЫ',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontFamily: 'Inter',
                                                      fontSize: 20*fframe,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1*fframe/frame,
                                                      height: 1.3*fframe,
                                                    ),
                                                  )
                                                ),
                                                DataColumn(label: 
                                                  Text('КЛАСС',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontFamily: 'Inter',
                                                      fontSize: 20*fframe,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1*fframe/frame,
                                                      height: 1.3*fframe,
                                                    ),
                                                  )
                                                ),
                                                DataColumn(label: 
                                                  Text('ВРЕМЯ РЕГИСТРАЦИИ',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontFamily: 'Inter',
                                                      fontSize: 20*fframe,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1*fframe/frame,
                                                      height: 1.3*fframe,
                                                    ),
                                                  )
                                                ),
                                                DataColumn(label: 
                                                  Text('КОЛИЧЕСТВО',
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontFamily: 'Inter',
                                                      fontSize: 20*fframe,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 1*fframe/frame,
                                                      height: 1.3*fframe,
                                                    ),
                                                  )
                                                ),
                                              ],
                                              rows: dataList.map((data) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 10*fframe, horizontal: 5*fframe),
                                                        child: Text(data.column1.join("\n\n"),
                                                        // shortcall(data.column1.join("\n\n"), 16)
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Color(0xFFFFFFFF),
                                                            fontFamily: 'Inter',
                                                            fontSize: 18*fframe,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 2*fframe/frame,
                                                            height: 1.3*fframe,
                                                          ),
                                                        ),
                                                      )
                                                    ),
                                                    DataCell(
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 10*fframe, horizontal: 5*fframe),
                                                        child: Text(data.column2.join("\n\n"),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Color(0xFFFFFFFF),
                                                            fontFamily: 'Inter',
                                                            fontSize: 18*fframe,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 2*fframe/frame,
                                                            height: 1.3*fframe,
                                                          ),
                                                        ),
                                                      )
                                                    ),
                                                    DataCell(
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 10*fframe, horizontal: 5*fframe),
                                                        child: Text(data.column3.join("\n\n"),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Color(0xFFFFFFFF),
                                                            fontFamily: 'Inter',
                                                            fontSize: 18*fframe,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 2*fframe/frame,
                                                            height: 1.3*fframe,
                                                          ),
                                                        ),
                                                      )
                                                    ),
                                                    DataCell(
                                                      Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 10*fframe, horizontal: 5*fframe),
                                                        child: Text(data.column4.join("\n\n"),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Color(0xFFFFFFFF),
                                                            fontFamily: 'Inter',
                                                            fontSize: 18*fframe,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 2*fframe/frame,
                                                            height: 1.3*fframe,
                                                          ),
                                                        ),
                                                      )
                                                    ),
                                                  ],
                                                  onSelectChanged: (bool? selected) {
                                                    if (selected != null && selected) {
                                                      setState(() {
                                                        newfileargs.add(data.column1.join("\n\n"));
                                                        newfileargs.add(data.column2.join("\n\n"));
                                                        newfileargs.add(data.column3.join("\n\n"));
                                                        newfileargs.add(data.column4.join("\n\n"));
                                                      });
                                                      if (dataEmptyFlag == false) {
                                                        Navigator.push(
                                                          context,
                                                          PageRouteBuilder(
                                                            pageBuilder: (_, __, ___) =>  ExtImagesWidget(dataList: dataList, fileargs: newfileargs, images: images, dataEmptyFlag: dataEmptyFlag, prevpage: ImagesWidget(filesarr: filesarr, dataEmptyFlag: dataEmptyFlag, prevpage: prevpage, userData:userData), userData:userData),
                                                            transitionsBuilder: (_, animation, __, child) {
                                                              return FadeTransition(
                                                                opacity: animation,
                                                                child: child,
                                                              );
                                                            }
                                                          )
                                                        );
                                                      }
                                                      else {
                                                        newfileargs = [];
                                                      }
                                                    }
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        )
                                      ),
                                      SizedBox(
                                        height: 15*fframe,
                                      ),
                                      SizedBox(
                                        child: Text('Статистика',
                                          textAlign: TextAlign.center, 
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontFamily: 'Oswald',
                                            fontSize: 30*fframe,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 5*fframe/frame,
                                            height: 1.3*fframe/frame,
                                          )
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10*fframe,
                                      ),
                                      Container(
                                        width: 1000*fframe,
                                        height: 310*fframe,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF20333E),
                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                        ),
                                        padding: EdgeInsets.all(20*fframe),
                                        child: Row(
                                          children: [
                                            // ЗАМЕНИТЬ
                                            if (zipplot)
                                            Column(
                                              children: [
                                                Container(
                                                  width: 400*fframe,
                                                  height: 250*fframe,
                                                  padding: EdgeInsets.fromLTRB(0*fframe, 20*fframe, 0*fframe, 0*fframe),
                                                  child: BarChart(
                                                    BarChartData(
                                                      barGroups: [
                                                        generateGroupData(1, 10),
                                                        generateGroupData(2, 18),
                                                        generateGroupData(3, 4),
                                                        generateGroupData(4, 11),
                                                      ],
                                                      maxY: 25,
                                                      barTouchData: BarTouchData(
                                                        enabled: true,
                                                        handleBuiltInTouches: false,
                                                        touchCallback: (event, response) {
                                                          if (response != null && response.spot != null && event is FlTapUpEvent) {
                                                            setState(() {
                                                              final x = response.spot!.touchedBarGroup.x;
                                                              final isShowing = showingTooltip == x;
                                                              if (isShowing) {
                                                                showingTooltip = -1;
                                                              } else {
                                                                showingTooltip = x;
                                                              }
                                                            });
                                                          }
                                                          else {
                                                            setState(() {
                                                              Future.delayed(Duration(seconds: 3), (){showingTooltip = -1;});
                                                              
                                                            });
                                                          }
                                                        },
                                                        mouseCursorResolver: (event, response) {
                                                          return response == null || response.spot == null
                                                              ? MouseCursor.defer
                                                              : SystemMouseCursors.click;
                                                        }
                                                      ),
                                                      // borderData: FlBorderData(
                                                      //   show: true,
                                                      //   border: Border.all(
                                                      //     color: Color(0xFFFFFFFF),
                                                      //   )
                                                      // ),
                                                      gridData: FlGridData(
                                                        show: true,
                                                        getDrawingHorizontalLine: (value) {
                                                          return FlLine(
                                                            color: Color.fromARGB(101, 255, 255, 255),
                                                            strokeWidth: 0.8,
                                                          );
                                                        },
                                                        getDrawingVerticalLine: (value) {
                                                          return FlLine(
                                                            color: Color.fromARGB(101, 255, 255, 255),
                                                            strokeWidth: 0.8,
                                                          );
                                                        },
                                                      ),
                                                      titlesData: FlTitlesData(
                                                        show: true,
                                                        bottomTitles: AxisTitles(
                                                          sideTitles: SideTitles(
                                                            showTitles: true,
                                                            reservedSize: 32,
                                                            getTitlesWidget: bottomTitles,
                                                          ),
                                                        ),
                                                        leftTitles: AxisTitles(
                                                          sideTitles: SideTitles(
                                                            showTitles: true,
                                                            reservedSize: 32,
                                                            getTitlesWidget: leftTitles,
                                                          ),
                                                        ),
                                                        rightTitles: AxisTitles(
                                                          sideTitles: SideTitles(
                                                            showTitles: false,
                                                            reservedSize: 32,
                                                            getTitlesWidget: leftTitles,
                                                          ),
                                                        ),
                                                        topTitles: AxisTitles(
                                                          sideTitles: SideTitles(
                                                            showTitles: false,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text('Длительность регистраций',
                                                  textAlign: TextAlign.center, 
                                                  style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontFamily: 'Inter',
                                                    fontSize: 14*fframe,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 1*fframe/frame,
                                                    height: 1.3*fframe/frame,
                                                  )
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              width: 120*fframe,
                                            ),
                                            if (zipplot)
                                            Row(
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: 300*fframe,
                                                      height: 250*fframe,
                                                      child: PieChart(
                                                        PieChartData (
                                                          pieTouchData: PieTouchData(
                                                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                              setState(() {
                                                                if (!event.isInterestedForInteractions ||
                                                                    pieTouchResponse == null ||
                                                                    pieTouchResponse.touchedSection == null) {
                                                                  touchedIndex = -1;
                                                                  return;
                                                                }
                                                                touchedIndex = pieTouchResponse
                                                                    .touchedSection!.touchedSectionIndex;
                                                              });
                                                            },
                                                          ),
                                                          borderData: FlBorderData(
                                                            show: false,
                                                          ),
                                                          sectionsSpace: 3,
                                                          centerSpaceRadius: 40,
                                                          sections: showingSections([20, 50, 15, 15]),
                                                        )
                                                      ),
                                                    ),
                                                    Text('Распределение классов',
                                                      textAlign: TextAlign.center, 
                                                      style: TextStyle(
                                                        color: Color(0xFFFFFFFF),
                                                        fontFamily: 'Inter',
                                                        fontSize: 14*fframe,
                                                        fontWeight: FontWeight.w500,
                                                        letterSpacing: 1*fframe/frame,
                                                        height: 1.3*fframe/frame,
                                                      )
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Row(children: [
                                                      Container(
                                                        width: 10*fframe,
                                                        height: 10*fframe,
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFF5FC1E0),
                                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10*fframe,
                                                      ),
                                                      Text('1 класс',
                                                        textAlign: TextAlign.center, 
                                                        style: TextStyle(
                                                          color: Color(0xFFFFFFFF),
                                                          fontFamily: 'Inter',
                                                          fontSize: 14*fframe,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 1*fframe/frame,
                                                          height: 1.3*fframe/frame,
                                                        )
                                                      ),
                                                    ],),
                                                    SizedBox(
                                                      height: 4,
                                                    ),
                                                    Row(children: [
                                                      Container(
                                                        width: 10*fframe,
                                                        height: 10*fframe,
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFF1F77B4),
                                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10*fframe,
                                                      ),
                                                      Text('2 класс',
                                                        textAlign: TextAlign.center, 
                                                        style: TextStyle(
                                                          color: Color(0xFFFFFFFF),
                                                          fontFamily: 'Inter',
                                                          fontSize: 14*fframe,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 1*fframe/frame,
                                                          height: 1.3*fframe/frame,
                                                        )
                                                      ),
                                                    ],),
                                                    SizedBox(
                                                      height: 4,
                                                    ),
                                                    Row(children: [
                                                      Container(
                                                        width: 10*fframe,
                                                        height: 10*fframe,
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFF437590),
                                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10*fframe,
                                                      ),
                                                      Text('3 класс',
                                                        textAlign: TextAlign.center, 
                                                        style: TextStyle(
                                                          color: Color(0xFFFFFFFF),
                                                          fontFamily: 'Inter',
                                                          fontSize: 14*fframe,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 1*fframe/frame,
                                                          height: 1.3*fframe/frame,
                                                        )
                                                      ),
                                                    ],),
                                                    SizedBox(
                                                      height: 4,
                                                    ),
                                                    Row(children: [
                                                      Container(
                                                        width: 10*fframe,
                                                        height: 10*fframe,
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFFFFFFFF),
                                                          borderRadius: BorderRadius.circular(15.0*fframe),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 10*fframe,
                                                      ),
                                                      Text('4 класс',
                                                        textAlign: TextAlign.center, 
                                                        style: TextStyle(
                                                          color: Color(0xFFFFFFFF),
                                                          fontFamily: 'Inter',
                                                          fontSize: 14*fframe,
                                                          fontWeight: FontWeight.w500,
                                                          letterSpacing: 1*fframe/frame,
                                                          height: 1.3*fframe/frame,
                                                        )
                                                      ),
                                                    ],),
                                                    SizedBox(
                                                      height: 4,
                                                    ),

                                                  ],
                                                ),
                                              ],
                                            )
                                          ],
                                        )

                                      ),
                                    ],
                                  ),
                                ],
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

  List<PieChartSectionData> showingSections(List<double?> values) {
    return List.generate(4, (i) {
        final isTouched = i == touchedIndex;
        final fontSize = isTouched ? 25.0 : 16.0;
        final radius = isTouched ? 60.0 : 50.0;
        switch (i) {
        case 0:
          return PieChartSectionData(
            color: Color(0xFF5FC1E0),
            value: values[0],
            title: '${values[0]?.round()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Color(0xFF1F77B4),
            value: values[1],
            title: '${values[1]?.round()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Color(0xFF437590),
            value: values[2],
            title: '${values[2]?.round()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
            ),
          );
        case 3:
          return PieChartSectionData(
            color: Color(0xFFFFFFFF),
            value: values[3],
            title: '${values[3]?.round()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000000),
            ),
          );
        default:
          throw Error();
      }
      }
    );
  }

  int touchedIndex = -1;

  late int showingTooltip;

  BarChartGroupData generateGroupData(int x, int y) {
    return BarChartGroupData(
      x: x,
      showingTooltipIndicators: showingTooltip == x ? [0] : [],
      barRods: [
        BarChartRodData(toY: y.toDouble()),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta,) {
    double baseWidth = 1600;
    double frame = MediaQuery.of(context).size.width / baseWidth;
    double fframe = frame * 0.97;
    var style = TextStyle(
      color: Color(0xFFFFFFFF),
        fontFamily: 'Inter',
        fontSize: 14*fframe,
        fontWeight: FontWeight.w500,
        letterSpacing: 5*fframe/frame,
        height: 1.3*fframe/frame,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.round().toString(), style: style),
    );
  }
  
  Widget leftTitles(double value, TitleMeta meta,) {
    double baseWidth = 1600;
    double frame = MediaQuery.of(context).size.width / baseWidth;
    double fframe = frame * 0.97;
    var style = TextStyle(
      color: Color(0xFFFFFFFF),
        fontFamily: 'Inter',
        fontSize: 14*fframe,
        fontWeight: FontWeight.w500,
        height: 1.3*fframe/frame,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.round().toString(), style: style),
    );
  }

  Widget rightTitles(double value, TitleMeta meta,) {
    double baseWidth = 1600;
    double frame = MediaQuery.of(context).size.width / baseWidth;
    double fframe = frame * 0.97;
    var style = TextStyle(
      color: Color(0xFFFFFFFF),
        fontFamily: 'Inter',
        fontSize: 14*fframe,
        fontWeight: FontWeight.w500,
        letterSpacing: 5*fframe/frame,
        height: 1.3*fframe/frame,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.round().toString(), style: style),
    );
  }
}



class DataModel {
  List<dynamic> column1;
  List<dynamic> column2;
  List<dynamic> column3;
  List<dynamic> column4;

  DataModel({required this.column1, required this.column2, required this.column3, required this.column4});

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      column1: json['name'],
      column2: json['class'],
      column3: json['date_registration'],
      column4: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': column1,
      'class': column2,
      'date_registration': column3,
      'count': column4,
    };
  }

  // static void updateDataModel(List<DataModel> dataList, List<String> newData) {
  //   final String matchString = newData[0];
  //   final String newColumn2 = newData[1];
  //   final List<String> newColumn3 = [newData[2]];

  //   for (DataModel dataModel in dataList) {
  //     if (dataModel.column1 == matchString) {
  //       dataModel.column2 = newColumn2;
  //       dataModel.column3 = newColumn3;
  //       break;
  //     }
  //   }
  // }
}




// SizedBox(
                                                //   width: 400*fframe,
                                                //   child: Row(
                                                //     mainAxisAlignment: MainAxisAlignment.start,
                                                //     crossAxisAlignment: CrossAxisAlignment.start,
                                                //     children: <Widget>[
                                                //       // ElevatedButton.icon(
                                                //       //   icon: loadingFlag
                                                //       //       ? const Center(child: SizedBox(width: 35, height: 35, child: CircularProgressIndicator(color: Color(0xFF000000) )))
                                                //       //       : const Icon(Icons.add_rounded, color: Color(0xFF000000), size: 35,),
                                                //       //   label: Text(
                                                //       //     loadingFlag ? 'АНАЛИЗ...' : ' ФОТО',
                                                //       //     style: TextStyle(
                                                //       //       fontFamily: 'Inter', 
                                                //       //       fontSize: 23*fframe,
                                                //       //       fontWeight: FontWeight.w700,
                                                //       //       height: 1.3*fframe/frame,
                                                //       //       color: Color(0xFF000000),
                                                //       //     ),
                                                //       //   ),
                                                //       //   onPressed: () => loadingFlag ? null : uploadImage(context),
                                                //       //   style: 
                                                //       //   ElevatedButton.styleFrom(
                                                //       //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                                                //       //     side: const BorderSide(color: Color(0xFFF9F8F6), width: 0),
                                                //       //     padding: const EdgeInsets.all(14),
                                                //       //     backgroundColor: Color(0xFFF9F8F6),
                                                //       //   ),
                                                //       // ),
                                                //       SizedBox(
                                                //         width: 20*fframe,
                                                //       ),
                                                //       // ElevatedButton.icon(
                                                //       //   icon: loadingFlag2
                                                //       //       ? const Center(child: SizedBox(width: 35, height: 35, child: CircularProgressIndicator(color: Color(0xFF000000) )))
                                                //       //       : const Icon(Icons.add_rounded, color: Color(0xFF000000), size: 35,),
                                                //       //   label: Text(
                                                //       //     loadingFlag2 ? 'АНАЛИЗ...' : 'АРХИВ',
                                                //       //     style: TextStyle(
                                                //       //       fontFamily: 'Inter', 
                                                //       //       fontSize: 23*fframe,
                                                //       //       fontWeight: FontWeight.w700,
                                                //       //       height: 1.3*fframe/frame,
                                                //       //       color: Color(0xFF000000),
                                                //       //     ),
                                                //       //   ),
                                                //       //   onPressed: () => loadingFlag ? null : uploadZip(context),
                                                //       //   // onPressed: () { loadingFlag = false; },
                                                //       //   style: 
                                                //       //   ElevatedButton.styleFrom(
                                                //       //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                                                //       //     side: const BorderSide(color: Color(0xFFF9F8F6), width: 0),
                                                //       //     padding: const EdgeInsets.all(14),
                                                //       //     backgroundColor: Color(0xFFF9F8F6),
                                                //       //   ),
                                                //       // ),
                                                //     ],
                                                //   ),
                                                // ),