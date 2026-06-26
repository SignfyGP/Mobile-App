import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:signfy/core/constants/strings.dart';

class CameraRecorderPage extends StatefulWidget {
  const CameraRecorderPage({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<CameraRecorderPage> createState() => _CameraRecorderPageState();
}

class _CameraRecorderPageState extends State<CameraRecorderPage> {
  CameraController? _cameraController;
  Future<void>? _initFuture;
  bool _isRecording = false;
  late int _cameraIndex;

  @override
  void initState() {
    super.initState();
    final frontIndex = widget.cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    _cameraIndex = frontIndex >= 0 ? frontIndex : 0;
    _setupController(widget.cameras[_cameraIndex]);
  }

  void _setupController(CameraDescription camera) {
    final controller = CameraController(camera, ResolutionPreset.high);
    _cameraController = controller;
    _initFuture = controller.initialize();
  }

  Future<void> _switchCamera() async {
    if (_isRecording || widget.cameras.length < 2) return;
    final nextIndex = (_cameraIndex + 1) % widget.cameras.length;
    await _cameraController?.dispose();
    if (!mounted) return;
    setState(() {
      _cameraIndex = nextIndex;
      _setupController(widget.cameras[nextIndex]);
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      if (_isRecording) {
        final file = await controller.stopVideoRecording();
        if (mounted) Navigator.pop(context, file.path);
      } else {
        await controller.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSwitch = widget.cameras.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.recordVideoTitle),
        actions: [
          if (canSwitch)
            IconButton(
              onPressed: _isRecording ? null : _switchCamera,
              icon: const Icon(Icons.cameraswitch_rounded),
              tooltip: S.switchCamera,
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snapshot) {
            final controller = _cameraController;
            if (snapshot.connectionState != ConnectionState.done ||
                controller == null ||
                !controller.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Expanded(child: Center(child: CameraPreview(controller))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop_circle : Icons.videocam,
                        ),
                        label: Text(
                          _isRecording ? S.stopRecording : S.startRecording,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(S.cancel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
