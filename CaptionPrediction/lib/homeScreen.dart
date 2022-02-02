import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

import 'liveCamera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //flag to check if the program is loading?
  bool isLoading = true;
  //defined an image to show results
  late File image;
  //this will show up when fetching data from API
  String resultText = "Sonuçlar getiriliyor...";
  //define an ImagePicker object to let user choose files from user's device
  final imagePicker = ImagePicker();


  //connecting with api and get result of a given image file
  Future<Map<String,dynamic>?> getResponse(File imageFile) async{
    //save data types into typeData
    final typeData = lookupMimeType(imageFile.path, headerBytes: [0xFF,0xD8])!.split("/");
    //POSTING OUR IMAGE TO API URL
    final imgUploadRequest = http.MultipartRequest("POST", Uri.parse("http://image-prediction-model-d3manch1-dev.apps.sandbox.x8i5.p1.openshiftapps.com/model/predict"));
    //CHECK THE TYPE
    final file = await http.MultipartFile.fromPath("image", imageFile.path, contentType: MediaType(typeData[0],typeData[1]));
    imgUploadRequest.fields["ext"]=typeData[1];
    imgUploadRequest.files.add(file);

    //SEND THE REQUEST GET RESPONSE AND RETURN
    try{
      final responseUpload = await imgUploadRequest.send();
      //GET RESPONSE JSON
      final response = await http.Response.fromStream(responseUpload);
      //DECODE THE JSON
      final Map<String, dynamic> responseData = json.decode(response.body);
      parseResponse(responseData);
      return responseData;
    }
    catch(e){
      //print the error
      print(e);
      return null;
    }

  }

  parseResponse(var response){
    //create an empty result at start
    String result = "";
    //get predictions from uploaded img file
    var predictions = response["predictions"];
    //to get the index of this iteration, it will start from '0'
    int order=0;
    //loop predictions with for each
    for(var pred in predictions){
      //increase the index for each element, so we can get their orders 1-2-3-4
      order++;
      //get each prediction to our caption variable with their order number
      var caption = order.toString()+" - " +pred["caption"];
      //todo:process probability value later
      var probability = pred["probability"];
      result =  result + caption + "\n";
    }

    //this is going to change our textfields with our parsed result string
    setState(() {
      resultText = result;
    });
  }

  //our first function to let users pick images from their gallery.
  pickImageFromGallery() async{
    var imageFile = await imagePicker.getImage(source: ImageSource.gallery);
    //if image file is not nyll
    if(imageFile != null){
      setState(() {
        image = File(imageFile.path);
        isLoading=false;
      });
      //user choose the image from device gallery, now send it to api
      var res = getResponse(image);
    }
  }

  captureImageWithCamera() async{
    var imageFile = await imagePicker.getImage(source: ImageSource.camera);
    //if image file is not null
    if(imageFile != null){
      setState(() {
        image = File(imageFile.path);
        isLoading=false;
      });
      var res = getResponse(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background-img.jpg"),
            fit: BoxFit.cover,
          )
        ),
        child: Container(
          padding: EdgeInsets.all(30.0),

          child: Column(
            children: [
              Center(

                child: isLoading
                    //if true display uuser interface
                    ? Container(
                    padding:EdgeInsets.only(top: 180.0),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow:
                          [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0,199),
                            )
                          ],
                        ),
                  child: Column(
                    children: [
                      SizedBox(height: 15.0,),
                      Container(
                        width: 600.0,
                        child: Image.asset("assets/camera.jpg")
                      ),
                      SizedBox(height:50.0,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          //live camera
                          SizedBox.fromSize(
                            size: Size(80,80),
                            child: ClipOval(
                              child: Material(
                                color: Colors.blueAccent,
                                child: InkWell(
                                  splashColor:  Colors.white,
                                  onTap: (){
                                    print("clicked");
                                    Navigator.push(context,MaterialPageRoute(builder: (context)=> CameraLive()));
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_front,size:40,color: Colors.white,),
                                      Text("Video Çek",style:TextStyle(fontSize: 10.0,color: Colors.white,fontWeight: FontWeight.bold),),
                                    ],
                                  )
                                ),
                              )
                            ),
                          ),


                          SizedBox(width: 4.0,),


                          //pick from gallery
                          SizedBox.fromSize(
                            size: Size(120,120),
                            child: ClipOval(
                                child: Material(
                                  color: Colors.blueAccent,
                                  child: InkWell(
                                      splashColor:  Colors.white,
                                      onTap: (){
                                        pickImageFromGallery();
                                        print("clicked");
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.photo,size:54,color: Colors.white,),
                                          Text("Galeriden Seç",style:TextStyle(fontSize: 15.0,color: Colors.white,fontWeight: FontWeight.bold),),
                                        ],
                                      )
                                  ),
                                )
                            ),
                          ),

                          
                          SizedBox(width: 4.0,),

                          //capture image with camera
                          SizedBox.fromSize(
                            size: Size(80,80),
                            child: ClipOval(
                                child: Material(
                                  color: Colors.blueAccent,
                                  child: InkWell(
                                      splashColor:  Colors.white,
                                      onTap: (){
                                        captureImageWithCamera();
                                        print("clicked");
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt,size:40,color: Colors.white,),
                                          Text("Fotoğraf Çek",style:TextStyle(fontSize: 10.0,color: Colors.white,fontWeight: FontWeight.bold),),
                                        ],
                                      )
                                  ),
                                )
                            ),
                          ),


                        ],
                      ),

                      SizedBox(width: 20.0,),
                    ],
                  ),
                )
                    //display for showing results
                    : Container(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.0),
                                boxShadow:
                            [
                            BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0,250),
                          )
                        ],
                            ),
                            height: 200.0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: IconButton(
                                    onPressed: (){
                                      print("clicked");
                                      setState(() {
                                        resultText = "Sonuçlar getiriliyor...";
                                        isLoading = true;
                                      });
                                    },
                                    icon: Icon(Icons.arrow_back_ios_outlined),
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  width: MediaQuery.of(context).size.width - 140,
                                  child:ClipRRect(
                                    borderRadius: BorderRadius.circular((10.0)),
                                    child: Image.file(image, fit: BoxFit.fill,),

                                  )
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height:60.0,),

                          Container(

                            child: Text(
                              resultText,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white,fontSize:24.0,fontWeight: FontWeight.bold)
                            )
                          )
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
