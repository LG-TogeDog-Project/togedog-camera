import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yolo_live_stream/yolo_live_stream.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _permissionGranted = false;
  LiveStreamingController? _controller;
  bool _wasConnected = false;
  bool _restarting = false;
  // 시작/재시작마다 후면 카메라를 한 번 적용했는지. 로컬 영상이 끊기면 다시 false.
  bool _rearApplied = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    final granted =
        statuses.values.every((s) => s == PermissionStatus.granted);
    if (granted) {
      _controller = LiveStreamingController(
        role: Role.sender,
        quality: VideoQuality.fullHd1080,
        enableDetection: false,
        enableSpeaker: false,
      )..addListener(_onControllerUpdate);
    }
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
  }

  // 수신폰이 끊기면(연결 true→false) 송신 세션을 새 peerConnection으로 리셋한다.
  // 패키지는 송신 PC를 1번만 만들고 재접속 때 같은 PC에 offer만 다시 보내는데,
  // 그러면 한 번 낮아진 인코더(해상도/비트레이트) 상태가 그대로 남아 재접속 화질이 계속 나빠진다.
  void _onControllerUpdate() {
    final controller = _controller;
    if (controller == null) return;

    // 패키지는 항상 전면(셀카, facingMode "user")으로 카메라를 연다. 강아지 시점은 후면이므로,
    // 시작/재시작마다 로컬 영상이 올라오는 순간 후면으로 한 번 전환한다.
    // (재접속 때 _restartSession이 startAsSender를 다시 불러 셀카로 되돌아가는 문제 해결)
    final hasLocalVideo = controller.connection.hasLocalVideo;
    if (hasLocalVideo && !_rearApplied) {
      _rearApplied = true;
      _applyRearCamera();
    } else if (!hasLocalVideo) {
      _rearApplied = false;
    }

    final connected = controller.isConnected;
    if (_wasConnected && !connected && !_restarting) {
      _restartSession();
    }
    _wasConnected = connected;
  }

  // 패키지가 전면으로 열기 때문에 한 번 전환하면 후면이 된다.
  // 사용자가 세션 도중 수동으로 다시 전면으로 바꾸면 _rearApplied가 유지돼 간섭하지 않는다.
  Future<void> _applyRearCamera() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.switchCamera();
  }

  Future<void> _restartSession() async {
    final controller = _controller;
    if (controller == null) return;
    _restarting = true;
    await controller.stop();
    await controller.startAsSender();
    _restarting = false;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_permissionGranted || controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            '카메라 및 마이크 권한이 필요합니다',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: LiveStreamingView(
        role: Role.sender,
        controller: controller,
        showMirrorButton: true,
        showPip: false,
      ),
    );
  }
}
