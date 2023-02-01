import 'dart:typed_data';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:collection/collection.dart';

class MeasurePage extends StatefulWidget {
  @override
  _MeasurePageState createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> {
  late ARKitController arkitController;
  vector.Vector3? lastPosition;
  String distance = '0';

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
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
              enableTapRecognizer: true,
             autoenablesDefaultLighting: true,
              showFeaturePoints: true,
              showWorldOrigin: true,
              worldAlignment: ARWorldAlignment.camera,
              detectionImages: const [
                ARKitReferenceImage(
                  name: 'assets/images/uf1.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf2.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf3.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf4.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf5.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf6.png',
                  physicalWidth: 0.14,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf7.png',
                  physicalWidth: 0.11,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf8.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf9.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf10.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf11.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf12.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf13.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf14.png',
                  physicalWidth: 0.11,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf15.png',
                  physicalWidth: 0.10,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf16.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf17.png',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf18.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf19.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf20.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf21.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf22.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf23.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf24.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf25.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf26.jpeg',
                  physicalWidth: 0.1,
                ),
                ARKitReferenceImage(
                  name: 'assets/images/uf27.jpeg',
                  physicalWidth: 0.1,
                ),
              ],
              onARKitViewCreated: onARKitViewCreated,

            ),
          ),
          Text(distance, style: Theme.of(context).textTheme.displayMedium),
        ],
      ));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = onAnchorWasFound;

    //this.arkitController.add(node)
    this.arkitController.onARTap = (ar) {
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
    };
  }

  Future<void> onAnchorWasFound(ARKitAnchor anchor) async {
    if (anchor is ARKitImageAnchor) {
      //setState(() => anchorWasFound = true);
      final earthPosition = anchor.transform.getColumn(3);
      /*print("Found X: ------------- ${earthPosition.x}");
      print("Found Y: ------------- ${earthPosition.y}");
      print("Found Z: ------------- ${earthPosition.z}");*/
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
        distance = _calculateDistanceBetweenPoints( positionA, position);
      });

      //Add Box Around Anchor
      final material = ARKitMaterial(
        //lightingModelName: ARKitLightingModel.lambert,
        diffuse: ARKitMaterialProperty.color(Colors.black),
        fillMode: ARKitFillMode.lines
      );

      final sphere = ARKitBox(
        materials: [material],
        width: 0.2,
        height: 0.2,
        length: 0.01,
        chamferRadius: 0
      );


      final node = ARKitNode(
        geometry: sphere,
        position: anchor.transform.getTranslation(),
        //eulerAngles: vector.Vector3.zero(),
        //rotation: anchor.transform.getRotation()
      );
      arkitController.add(node);
      //node.physicsBody.
      //this.arkitController.
      //arkitController.

      /*timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        final old = node.eulerAngles;
        final eulerAngles = vector.Vector3(old.x + 0.01, old.y, old.z);
        node.eulerAngles = eulerAngles;
      });*/
    }
  }

  void _onARTapHandler(vector.Vector3 position) {
    print("Depth: ------------- ${position.z}");

    final material = ARKitMaterial(
        lightingModelName: ARKitLightingModel.constant,
        diffuse: ARKitMaterialProperty.color(Colors.blue));
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
  }

  String _calculateDistanceBetweenPoints(vector.Vector3 A, vector.Vector3 B) {
    final length = A.distanceTo(B);
    return '${(length * 100).toStringAsFixed(2)} cm';
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
    );
    arkitController.add(node);
  }
}

