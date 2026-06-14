import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final Flutter3DController _controller = Flutter3DController();
  final TextEditingController _textController = TextEditingController();

  final List<String> _animationsList = ['291', '59', '294'];

  @override
  void initState() {
    super.initState();
    _controller.onModelLoaded.addListener(() {
      debugPrint('model loaded: ${_controller.onModelLoaded.value}');
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _playAnimations() async {
    FocusScope.of(context).unfocus();

    final available = await _controller.getAvailableAnimations();
    if (available.isEmpty || _animationsList.isEmpty) return;

    for (final name in _animationsList) {
      if (!available.contains(name)) continue;
      _controller.playAnimation(animationName: name);
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _controller.stopAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D Avatar Demo')),
      body: Column(
        children: [
          Expanded(
            child: Flutter3DViewer(
              activeGestureInterceptor: true,
              progressBarColor: const Color(0xFF00CFFF),
              enableTouch: true,
              controller: _controller,
              src: 'assets/models/sign_avatar.glb',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter text',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _playAnimations,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
