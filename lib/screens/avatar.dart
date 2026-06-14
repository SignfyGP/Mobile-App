import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';



class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});
  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final Flutter3DController controller = Flutter3DController();
  final TextEditingController textController = TextEditingController();
  var animateCounter=0;

  List<String> animationsList = ["291", "59", "294"];
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    controller.onModelLoaded.addListener(() {
      debugPrint('model is loaded : ${controller.onModelLoaded.value}');
    });
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontSize: 28),
    );
    return Scaffold(
      appBar: AppBar(
          title: const Text('Signfiy')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                child: Flutter3DViewer(
                  activeGestureInterceptor: true,
                   progressBarColor: const Color(0xFF00CFFF),
                  enableTouch: true,
                  onProgress: (double progressValue) {
                    debugPrint('model loading progress : $progressValue');
                  },
                  onLoad: (String modelAddress) {
                    debugPrint('model loaded : $modelAddress');
                  },
                  onError: (String error) {
                    debugPrint('model failed to load : $error');
                  },
                  controller: controller,
                  src: 'assets/models/sign_avatar.glb',

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
                  onPressed: () async {
                    FocusScope.of(context).unfocus();

                    final availableAnimations =
                      await controller.getAvailableAnimations();
                    print("Available Animations: ${availableAnimations}");
                    if (availableAnimations.isEmpty ||
                        animationsList.isEmpty) {
                      return;
                    }

                    for (final animationName in animationsList) {
                      if (!availableAnimations.contains(animationName)) {
                        continue;
                      }

                      controller.playAnimation(animationName: animationName);

                      // Give each animation time to play before starting the next.
                      await Future.delayed(const Duration(milliseconds: 1200));
                    }
                    // Reset avatar back to its initial animation frame.
                    // controller.resetAnimation();
                    await Future.delayed(const Duration(milliseconds: 300));
                    controller.stopAnimation();
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
                // ElevatedButton(
                //   onPressed: () async {
                //     // example: list animations and play first
                //     final animations = await controller.availableAnimations();
                //     print(animations);
                //     if (animations.isNotEmpty) {
                //       controller.animationName = animations[0];
                //       controller.play(repetitions: 1);
                    
                //     }
                //   },
                //   style: style,
                //   child: const Text('لا اعلم'),
                // ),
                // ElevatedButton(
                //   onPressed: () async {
                //     final animations = await controller.availableAnimations();
                //     if (animations.isNotEmpty) {
                //       controller.animationName = animations[2];
                //       controller.play(repetitions: 1);
                //     }
                //   },
                //   style: style,
                //   child: const Text('احترام'),
                // ),
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