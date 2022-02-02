import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CameraLive extends StatefulWidget {
  const CameraLive({Key? key}) : super(key: key);

  @override
  _CameraLiveState createState() => _CameraLiveState();
}

class _CameraLiveState extends State<CameraLive> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  bool takePhoto = false;
  String resultText = "Sonuçlar getiriliyor...";


  Future<void> detectCameras() async{
  cameras= await availableCameras();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    cameraController?.dispose();
  }

  @override
  void initState() {
    super.initState();
    takePhoto = true;
    detectCameras().then((value) {
      initializeControllers();
    });
  }

  //initialize the camera controllers
  void initializeControllers(){
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value)
    {
      if(!mounted){
        return;
      }
      setState(() {

      });
      if(takePhoto)
        {
          //interval
          const interval = const Duration(seconds: 6);
          //start capturing every 5
          new Timer.periodic(interval, (Timer t)=>startCapturingPictures());
        }
    });
  }

  startCapturingPictures() async{
    //every picture taken each 6 seconds will have their unique name
    String timeNameForPicture = DateTime.now().microsecondsSinceEpoch.toString();
    final Directory directory = await getApplicationDocumentsDirectory();
    final String dirPath = "${directory.path}/Pictures/flutter_test";
    await Directory(dirPath).create(recursive: true);
    final String filePath = "$dirPath/{$timeNameForPicture}.png";

    if(takePhoto){
      cameraController.takePicture(filePath).then((value){
        if(takePhoto){
          File imgFile = File(filePath);
          getResponse(imgFile);
        }
        else{
          return;
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        //setting background
        decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background-img.jpg"),
              fit: BoxFit.cover,
            )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Container(
              padding: EdgeInsets.only(top:30.0),
              child: IconButton(
                color:Colors.white,
                icon: Icon(Icons.arrow_back_ios_outlined),
                onPressed: (){
                  setState(() {
                    takePhoto = false;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            (cameraController.value.isInitialized)
            //if its initialized create camera view
                ?Center(child: createCameraView(),)
            //if its not display empty container
                :Container()
          ],
        ),
      ),
    );
  }

  //getting cameraview
  Widget createCameraView(){
    var size = MediaQuery.of(context).size.width / 1.2;
    return Column(
      children: [
        Container(
          child: Column(
            children: [
              SizedBox(height: 30,),
              Container(
                width: size,
                height: size,
                child: CameraPreview(cameraController),
              ),
              SizedBox(height: 30,),
              //prediction is - > resulttext from api
              Text(
                "Sonuçlar: \n",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
              //resulttext from api
              Text(
                resultText,
                style: TextStyle(fontSize: 16,fontWeight: FontWeight.w300,color:Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      ],
    );
  }
}
