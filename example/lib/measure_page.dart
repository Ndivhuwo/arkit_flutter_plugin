import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arkit_plugin_example/snapshot_scene.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:torch_controller/torch_controller.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'painters/coordinates_translator.dart';

class MeasurePage extends StatefulWidget {
  @override
  _MeasurePageState createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  late ARKitController arkitController;
  vector.Vector3? lastPosition;
  String meanDistance = '0';
  String averageDistance = '0';
  String calculatedDistance = '0';
  late Timer timer;
  late ObjectDetector objectDetector;
  bool busyProcessing = false;
  int maxDuration = 60;
  int loopMLKitCount = 0;
  List<int> mlDetectedOBj = [];
  bool nodesAdded = false;
  List<double> heights = [];
  List<double> cameraDistances = [];
  double estimatedSensorHeight = 6.63;
  final torchController = TorchController();

  @override
  void dispose() {
    arkitController.dispose();
    timer.cancel();
    lastPosition = null;
    objectDetector.close();
    //turnOffFlashLight();
    super.dispose();
  }

  @override
  void initState() {
    /*SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);*/
    //turnOnFlashLight();
    super.initState();
  }

  Future<void> turnOnFlashLight() async {
    try {
      await torchController.toggle();
    } catch (e) {
      print("FlashLight Error ${e.toString()}");
    }
  }

  Future<void> turnOffFlashLight() async {
    try {
      await torchController.toggle();
    }  catch (e) {
      print("FlashLight Error ${e.toString()}");
    }

  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Measure Sample'),
      ),
      body: Stack(
        children: [
          Container(
            child: ARKitSceneView(
              //detectionImages: [],
              //enableTapRecognizer: true,
              autoenablesDefaultLighting: true,
              //showFeaturePoints: true,
              //showWorldOrigin: true,
              worldAlignment: ARWorldAlignment.gravity,
              configuration: ARKitConfiguration.worldTracking,
              debug: true,
              onARKitViewCreated: (controller) {
                onARKitViewCreated(controller, context);
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Median: $meanDistance',
                  style: TextStyle(
                      color: Colors.white,
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 8.0,
                          color: Color.fromARGB(125, 0, 0, 255),
                        ),
                      ],
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 25,),
              Text('Average: $averageDistance',
                  style: TextStyle(
                      color: Colors.white,
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        Shadow(
                          offset: Offset(5.0, 5.0),
                          blurRadius: 8.0,
                          color: Color.fromARGB(125, 0, 0, 255),
                        ),
                      ],
                      fontSize: 20,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ));

  Future<void> _initializeDetector() async {
    final modelPath = await _getModel('assets/ml/model10.tflite');
    final options = LocalObjectDetectorOptions(
      modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: false,
      mode: DetectionMode.stream,
      confidenceThreshold: 0.60,
      //maximumLabelsPerObject: 3
    );
    objectDetector = ObjectDetector(options: options);
  }

  Future<void> onARKitViewCreated(ARKitController arkitController, BuildContext context) async {
    this.arkitController = arkitController;
    //this.arkitController.onAddNodeForAnchor = onAnchorWasFound;

    //this.arkitController.add(node)
    /*this.arkitController.onARTap = (ar) {
      ar.sort((a, b) => a.worldTransform.getColumn(3).z.compareTo(b.worldTransform.getColumn(3).z));
      final point = ar.firstWhereOrNull(
        (o) => o.type == ARKitHitTestResultType.featurePoint,
      );
      if (point != null) {
        final position = vector.Vector3(
          point.worldTransform.getColumn(3).x,
          point.worldTransform.getColumn(3).y,
          point.worldTransform.getColumn(3).z,
        );
        _onARTapHandler(position);
      }
    };*/
    await _initializeDetector();
    loopMLKitUpdate(context);
  }

  /*Future<void> onAnchorWasFound(ARKitAnchor anchor) async {
    if (anchor is ARKitImageAnchor) {
      //setState(() => anchorWasFound = true);
      final earthPosition = anchor.transform.getColumn(3);
      print("Found Length: ------------- ${earthPosition.length}");

      final position = vector.Vector3(
        earthPosition.x,
        earthPosition.y,
        earthPosition.z,
      );
      var positionA = await arkitController.cameraPosition() ?? vector.Vector3.zero();
      var positionA2 = await arkitController.cameraPosition();
      print("Camera Position: ------------- ${positionA2}");
      //_onARTapHandler(position);
      setState(() {
        meanDistance = _calculateDistanceBetweenPoints(positionA, position);
      });

      //Add Box Around Anchor
      final material = ARKitMaterial(
          //lightingModelName: ARKitLightingModel.lambert,
          diffuse: ARKitMaterialProperty.color(Colors.black),
          fillMode: ARKitFillMode.lines);

      final sphere = ARKitBox(materials: [material], width: 0.2, height: 0.2, length: 0.01, chamferRadius: 0);

      final node = ARKitNode(
        geometry: sphere,
        position: anchor.transform.getTranslation(),
        //eulerAngles: vector.Vector3.zero(),
        //rotation: anchor.transform.getRotation()
      );
      arkitController.add(node);

    }
  }*/

  /*void _onARTapHandler(vector.Vector3 position) {
    print("Depth: ------------- ${position.z}");

    final material = ARKitMaterial(lightingModelName: ARKitLightingModel.constant, diffuse: ARKitMaterialProperty.color(Colors.blue));
    final sphere = ARKitSphere(
      radius: 0.006,
      materials: [material],
    );
    final node = ARKitNode(
      geometry: sphere,
      position: position,
    );
    arkitController.add(node);

    if (lastPosition != null) {
      final line = ARKitLine(
        fromVector: lastPosition!,
        toVector: position,
      );
      final lineNode = ARKitNode(geometry: line);
      arkitController.add(lineNode);

      final distance = _calculateDistanceBetweenPoints(position, lastPosition!);
      final point = _getMiddleVector(position, lastPosition!);
      _drawText(distance, point);
    }
    lastPosition = position;
  }*/

  String _calculateDistanceBetweenPoints(vector.Vector3 A, vector.Vector3 B) {
    final length = A.distanceTo(B);
    return '${(length * 100).toStringAsFixed(2)} cm';
  }

  double _calculateDistanceBetweenPoints2MM(vector.Vector3 A, vector.Vector3 B) {
    final length = A.distanceTo(B);
    return (length * 1000);
  }

  vector.Vector3 _getMiddleVector(vector.Vector3 A, vector.Vector3 B) {
    return vector.Vector3((A.x + B.x) / 2, (A.y + B.y) / 2, (A.z + B.z) / 2);
  }

  void _drawText(String text, vector.Vector3 point) {
    final textGeometry = ARKitText(
      text: text,
      extrusionDepth: 1,
      materials: [
        ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(Colors.red),
        )
      ],
    );
    const scale = 0.001;
    final vectorScale = vector.Vector3(scale, scale, scale);
    final node = ARKitNode(
      geometry: textGeometry,
      position: point,
      scale: vectorScale,
      name: "textNode"
    );
    arkitController.add(node);
    nodesAdded = true;
    busyProcessing = false;
    if (mounted) {
      setState(() {});
    }
  }

  void loopMLKitUpdate(BuildContext context) {
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if(loopMLKitCount > maxDuration) {
        if(true) {
          arkitController.remove("position1");
          arkitController.remove("position2");
          arkitController.remove("lineNode");
          arkitController.remove("textNode");
          nodesAdded = false;
        }
        timer.cancel();
        if (heights.isNotEmpty) {
          heights.sort((a, b) => a.compareTo(b));
          print("Sorted List ${heights}");
          var outliers = getOutliers(heights);
          print("Outliers ${outliers}");
          outliers.forEach((element) {
            heights.remove(element);
          });
          print("Trimmed ${heights}");
          var median = getMedian(heights);
          var result = heights.reduce((value, element) => value + element) / heights.length;
          //setState(() {
          meanDistance = '${(median).toStringAsFixed(2)} mm';
          averageDistance = '${(result).toStringAsFixed(2)} mm';
          //});
        }
        final image = await arkitController.snapshot();
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SnapshotPreview(
              imageProvider: image,
              meanDistance: meanDistance,
              averageDistance: averageDistance,
            ),
          ),
        );
      }
      loopMLKitCount++;
      updateMLKit();
    });
  }

  ImageProvider? cameraSnapShot;

  Future<void> updateMLKit() async {
    if (busyProcessing && cameraSnapShot != null) {
      print("MLKit still busy.. Aborting loop session");
      return;
    }
    busyProcessing = true;
    if(true) {
      arkitController.remove("position1");
      arkitController.remove("position2");
      arkitController.remove("lineNode");
      arkitController.remove("textNode");
      nodesAdded = false;
    }
    cameraSnapShot = await arkitController.snapshot();
      late int imageHeight;
      late int imageWidth;
      final completer = Completer<ByteData?>();
      cameraSnapShot!.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
          (ImageInfo image, bool sync) async {
            imageHeight = image.image.height;
            imageWidth = image.image.width;
            completer.complete(await image.image.toByteData());
          },
        ),
      );

      var byteData = await completer.future;
    await cameraSnapShot?.evict();
        cameraSnapShot = null;
        final size = Size(imageWidth.toDouble(), imageHeight.toDouble());
        final inputImageFormat = InputImageFormat.bgra8888;
        final planeData = <InputImagePlaneMetadata>[
          InputImagePlaneMetadata(bytesPerRow: imageWidth * 4),
        ];
        //cameraSnapShot.
        InputImage? inputImage = InputImage.fromBytes(
            bytes: byteData!.buffer.asUint8List(),
            inputImageData: InputImageData(size: size, imageRotation: InputImageRotation.rotation0deg, inputImageFormat: inputImageFormat, planeData: planeData));
    byteData = null;
        objectDetector.processImage(inputImage).then((objects) {
          inputImage = null;
          processImage(objects, size);
        }).catchError((e) {
          busyProcessing = false;
          if (mounted) {
            setState(() {});
          }
        });
    //var cameraSnapShot = await arkitController.snapshot();
  }

  double getAverageVale(List<double> list) {
    if (list.length > 3) {
      list.sort((a, b) => a.compareTo(b));
      var outliers = getOutliers(list);
      outliers.forEach((element) {
        list.remove(element);
      });
      //var median = getMedian(list);
      var result = list.reduce((value, element) => value + element) / list.length;
      return result;
    } else {
      return 0;
    }
  }

  Future<void> processImage(
    List<DetectedObject> objects,
    Size size,
  ) async {
    var absoluteSize = size;
    var iterations = 0;
    objects.sort((a, b) {
      List<Label> aLables = a.labels.where((element) => element.text == "foot" /*&& element.confidence > 0.7*/).toList();
      aLables.sort((c, d) => c.confidence.compareTo(d.confidence));
      List<Label> bLabels = b.labels.where((element) => element.text == "foot" /*&& element.confidence > 0.7*/).toList();
        bLabels.sort((c, d) => c.confidence.compareTo(d.confidence));
      return (aLables.firstOrNull?.confidence ?? 0).compareTo(bLabels.firstOrNull?.confidence ?? 0);
    });
    var detectedObject = objects.firstOrNull;
    objects = [];

    if(detectedObject != null /*&& detectedObject.labels.any((element) => element.text == "foot" && element.confidence > 0.7)*/) {
      final left = translateX(detectedObject.boundingBox.left, InputImageRotation.rotation0deg, size, absoluteSize) / size.width;
      final top = translateY(detectedObject.boundingBox.top, InputImageRotation.rotation0deg, size, absoluteSize) / size.height;
      final right = translateX(detectedObject.boundingBox.right, InputImageRotation.rotation0deg, size, absoluteSize) / size.width;
      final bottom = translateY(detectedObject.boundingBox.bottom, InputImageRotation.rotation0deg, size, absoluteSize) / size.height;
      /*print('top: ---------------------: ${top}------------Unprocessed: ${detectedObject.boundingBox.top}');
      print('bottom: ---------------------: ${bottom} ------------Unprocessed: ${detectedObject.boundingBox.bottom}');
      print('height: ---------------------: ${top - bottom}------------Unprocessed: ${detectedObject.boundingBox.height}');
      print('Screen height: ---------------------:  ${size.height}');*/
      double heightPixels = (detectedObject.boundingBox.height).abs();

      var midX = (right + left) / 2;
      var midY = translateY(detectedObject.boundingBox.center.dy, InputImageRotation.rotation0deg, size, absoluteSize)  / size.height;//(top + bottom) / 2;
      //final bottomP = bottom
      detectedObject = null;

      try {
        double focalLength = (await arkitController.getFocalLength()) ?? 0;
        //double focalLengthExif = (await arkitController.get()) ?? 0;
        print('focalLength: ---------------------: ${focalLength}');
        var midPoint = await getFeaturePoint(left, right, midY, 2, true, null, top: top, bottom: bottom);

        print('Midpoint: ---------------------: ${midPoint?.distance}');
        double rawDistance  = midPoint?.distance ?? 0;
        if(rawDistance != 0 && rawDistance >= 0.15 && rawDistance <= 0.35) {
          //cameraDistances.add(rawDistance);
          double calculatedDistance = 0;//getAverageVale(cameraDistances);
          double distanceToFoot = calculatedDistance != 0 ? calculatedDistance: rawDistance;
          double distanceInMM = distanceToFoot * 1000;

          //double calculatedHeight = (distanceInMM *heightPixels* estimatedSensorHeight)/(focalLength * size.height);
          double calculatedHeight = (distanceInMM * heightPixels)/(size.height);
          print('calculatedHeight: ---------------------: ${calculatedHeight}');

          var bottomPoint = await getFeaturePoint(left, right, bottom, 2, true, distanceToFoot);//arkitController.performHitTest(x: midX, y: bottom);
          var topPoint = await getFeaturePoint(left, right, top, 2, true, distanceToFoot);
          midPoint = null;

          if (bottomPoint != null && topPoint != null) {
            var topPosition = vector.Vector3(
              topPoint.worldTransform.getColumn(3).x,
              topPoint.worldTransform.getColumn(3).y,
              topPoint.worldTransform.getColumn(3).z,
            );

            var bottomPosition = vector.Vector3(
              bottomPoint.worldTransform.getColumn(3).x,
              bottomPoint.worldTransform.getColumn(3).y,
              bottomPoint.worldTransform.getColumn(3).z,
            );
            topPoint = null;
            bottomPoint = null;
            measureDistance(topPosition, bottomPosition);
            //mlDetectedOBj.add(detectedObject.trackingId ?? -1);
          } else {
            print('Bottom or top point is null: ---------------------');
            busyProcessing = false;
            if (mounted) {
              setState(() {});
            }
          }
        } else {
          print('Distance too inaccurate: ---------------------');
          busyProcessing = false;
          if (mounted) {
            setState(() {});
          }
        }

      } catch (e) {
        print("An error occurred---------------${e.toString()}");
        busyProcessing = false;
        if (mounted) {
          setState(() {});
        }
      }

    } else {
      print('Detector Foot not found: -------------');
      busyProcessing = false;
      if (mounted) {
        setState(() {});
      }
    }
    /*for (final detectedObject in objects) {
      if (mlDetectedOBj.contains(detectedObject.trackingId)) {
        return;
      }

      var labelTxt = "";
      var confidence = 0.0;
      for (final label in detectedObject.labels) {
        //builder.addText('${label.text} ${label.confidence}\n');
        if (label.confidence > confidence) {
          labelTxt = label.text;
          confidence = label.confidence;
        }
      }
      print('Identied: -----------------${labelTxt} ------ $confidence');

      //arkitController.getCameraEulerAngles()

      //builder.pop();
      if (labelTxt == "foot" && confidence > 0.55) {
        //(await arkitController.cameraProjectionMatrix()).
        final left = translateX(detectedObject.boundingBox.left, InputImageRotation.rotation0deg, size, absoluteSize) / size.width;
        final top = translateY(detectedObject.boundingBox.top, InputImageRotation.rotation0deg, size, absoluteSize) / size.height;
        final right = translateX(detectedObject.boundingBox.right, InputImageRotation.rotation0deg, size, absoluteSize) / size.width;
        final bottom = translateY(detectedObject.boundingBox.bottom, InputImageRotation.rotation0deg, size, absoluteSize) / size.height;

        var midX = (right + left) / 2;
        //final bottomP = bottom

        try {
          arkitController.performHitTest(x: midX, y: bottom).then((bottomPointResults) {
            print('bottomPointResults: -----------------${bottomPointResults.where((element) => element.type == ARKitHitTestResultType.featurePoint).map((e) => e.toJson()).toList()}');
            //bottomPointResults.sort((a, b) => a.worldTransform.getColumn(3).z.compareTo(b.worldTransform.getColumn(3).z));
            var bottomPoint = bottomPointResults.firstWhereOrNull(
              (o) => o.type == ARKitHitTestResultType.featurePoint,
            );

            arkitController.performHitTest(x: midX, y: top).then((topPointResults) {
              print('topPointResults: -----------------${topPointResults.where((element) => element.type == ARKitHitTestResultType.featurePoint).map((e) => e.toJson()).toList()}');
              //topPointResults.sort((a, b) => a.worldTransform.getColumn(3).z.compareTo(b.worldTransform.getColumn(3).z));
              var topPoint = topPointResults.firstWhereOrNull(
                (o) => o.type == ARKitHitTestResultType.featurePoint,
              );

              if (bottomPoint != null && topPoint != null) {
                var topPosition = vector.Vector3(
                  topPoint.worldTransform.getColumn(3).x,
                  topPoint.worldTransform.getColumn(3).y,
                  topPoint.worldTransform.getColumn(3).z,
                );

                var bottomPosition = vector.Vector3(
                  bottomPoint.worldTransform.getColumn(3).x,
                  bottomPoint.worldTransform.getColumn(3).y,
                  bottomPoint.worldTransform.getColumn(3).z,
                );

                measureDistance(topPosition, bottomPosition);
                //mlDetectedOBj.add(detectedObject.trackingId ?? -1);
              }
            }).catchError((e) {
              print("topPointResults hittest error occurred---------------${e.toString()}");
            });
          }).catchError((e) {
            print("bottomPointResults hittest error occurred---------------${e.toString()}");
          });
        } catch (e) {
          print("An error occurred---------------${e.toString()}");
        }
      }

      iterations++;
    }*/

    /*if (iterations == objects.length) {
      busyProcessing = false;
      if (mounted) {
        setState(() {});
      }
    }*/
  }

  int getFeaturePointMaxRetries = 40;
  int getFeaturePointCount = 0;

  Future<ARKitTestResult?> getFeaturePoint(double left, double right, double y, double offset, bool first, double? depth, {double? top, double? bottom}) async {
    if(first) {
      getFeaturePointCount = 0;
    } else {
      getFeaturePointCount++;
    }
    var midX = (right + left) / offset;
    var pointResults =[];
    if(top != null && bottom != null) {
      var midY = (top + bottom) / offset;
      pointResults = await arkitController.performHitTest(x: midX, y: midY);
    } else {
      pointResults = await arkitController.performHitTest(x: midX, y: y);
    }
    var point = pointResults.firstWhereOrNull(
          (o) {
            if(depth != null) {
              return o.type == ARKitHitTestResultType.featurePoint && (o.distance >= (depth - 0.04) && o.distance <= (depth + 0.04));
            } else {
              return o.type == ARKitHitTestResultType.featurePoint;
            }

          } ,
    );

    if(point == null && getFeaturePointCount <= getFeaturePointMaxRetries) {
      return getFeaturePoint(left, right, y, doubleInRange(Random(), offset - 0.25, offset + 0.25), false, depth, top: top, bottom: bottom);
    } else {
      return point;
    }
  }

  double doubleInRange(Random source, num start, num end) =>
      source.nextDouble() * (end - start) + start;

  void measureDistance(vector.Vector3 position1, vector.Vector3 position2) {
    //print("Depth: -------------position1 ${position1.z}");
    //print("Depth: -------------position2 ${position2.z}");

    final material = ARKitMaterial(lightingModelName: ARKitLightingModel.constant, diffuse: ARKitMaterialProperty.color(Colors.blue));
    final sphere = ARKitSphere(
      radius: 0.005,
      materials: [material],
    );
    final node1 = ARKitNode(
      geometry: sphere,
      position: position1,
      name: "position1"
    );
    final node2 = ARKitNode(
      geometry: sphere,
      position: position2,
        name: "position2"
    );
    arkitController.add(node1);
    arkitController.add(node2);

    final line = ARKitLine(
      fromVector: position1,
      toVector: position2,
    );
    final lineNode = ARKitNode(geometry: line, name: "lineNode");
    arkitController.add(lineNode);

    final distance = _calculateDistanceBetweenPoints2MM(position1, position2);
    if(distance > 80 && distance < 370) {
      heights.add(distance);
      var distString = '${(distance).toStringAsFixed(2)} mm';
      final point = _getMiddleVector(position1, position2);
      _drawText(distString, point);
      setState(() {
        averageDistance = '${(distance).toStringAsFixed(2)} mm';
      });
      //calculateHeightAverage();
    } else {
      busyProcessing = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  calculateHeightAverage() {
    if (heights.isNotEmpty) {
      heights.sort((a, b) => a.compareTo(b));
      var outliers = getOutliers(heights);
      outliers.forEach((element) {
        heights.remove(element);
      });
      var median = getMedian(heights);
      var result = heights.reduce((value, element) => value + element) / heights.length;
      setState(() {
        meanDistance = '${(median).toStringAsFixed(2)} mm';
        averageDistance = '${(result).toStringAsFixed(2)} mm';
      });
    }
  }

  List<double> getOutliers(List<double> input) {
    List<double> output = [];
    List<double> data1 = [];
    List<double> data2 = [];
    if (input.length % 2 == 0) {
      data1 = input.sublist(0, (input.length / 2).round());
      data2 = input.sublist((input.length / 2).round(), input.length);
    } else {
      data1 = input.sublist(0, (input.length / 2).round());
      data2 = input.sublist((input.length / 2).round() + 1, input.length);
    }
    double q1 = getMedian(data1);
    double q3 = getMedian(data2);
    double iqr = q3 - q1;
    double lowerFence = q1 - 0.4 * iqr;
    double upperFence = q3 + 0.4 * iqr;
    for (int i = 0; i < input.length; i++) {
      if (input[i] < lowerFence || input[i] > upperFence)
        output.add(input[i]);
    }
    return output;
  }

  double getMedian(List<double> data) {

    if (data.length % 2 == 0) {
      return ((data[(data.length / 2).round()]) + (data[(data.length / 2 - 1).round()])) / 2;
    } else {
      return data[(data.length / 2).round()];
    }
  }

  Future<String> _getModel(String assetPath) async {
    if (Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
