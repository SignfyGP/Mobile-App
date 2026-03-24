import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';


class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});
  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final O3DController controller = O3DController();
  final TextEditingController textController = TextEditingController();
  var animateCounter=0;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 28),
    );
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text('Signfiy')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                child: O3D(
                  controller: controller,
                  src: 'assets/models/hero.glb',
                  autoPlay: false,
                  cameraControls: false,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter text',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // example: list animations and play first
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[0];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('لا اعلم'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[1];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('مرحبا'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final animations = await controller.availableAnimations();
                    if (animations.isNotEmpty) {
                      controller.animationName = animations[2];
                      controller.play(repetitions: 1);
                    }
                  },
                  style: style,
                  child: const Text('احترام'),
                ),
              ],
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.play_arrow),
      //   onPressed: () async {
      //     // example: list animations and play first
      //     final animations = await controller.availableAnimations();
      //     if (animations.isNotEmpty) {
      //       controller.animationName = animations[animateCounter];
      //       controller.play(repetitions: 1);
      //     }
      //     animateCounter++;
      //     animateCounter%=animations.length;
      //   },
      // ),
    );
  }
}