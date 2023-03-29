import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arkit_plugin_example/util/ar_helper.dart';
import 'package:flutter/material.dart';

class SnapshotScenePage extends StatefulWidget {
  @override
  _SnapshotScenePageState createState() => _SnapshotScenePageState();
}

class _SnapshotScenePageState extends State<SnapshotScenePage> {
  late ARKitController arkitController;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Snapshot'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            final image = await arkitController.snapshot();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SnapshotPreview(
                  imageProvider: image,
                ),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
      body: Container(
        child: ARKitSceneView(onARKitViewCreated: onARKitViewCreated),
      ));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.add(createSphere());
  }
}

class SnapshotPreview extends StatelessWidget {
  const SnapshotPreview({
    Key? key,
    required this.imageProvider, this.meanDistance, this.averageDistance
  }) : super(key: key);

  final ImageProvider imageProvider;
  final String? meanDistance;
  final String? averageDistance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: imageProvider),
          meanDistance != null && averageDistance != null ? Column(
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
          ):
              Container()
        ],
      ),
    );
  }
}
