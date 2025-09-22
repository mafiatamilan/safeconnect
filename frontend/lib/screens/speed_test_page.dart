// lib/screens/speed_test_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';

// Enum to manage UI state based on testing stage
enum TestStage { idle, download, upload, complete, error }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({Key? key}) : super(key: key);
  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> with TickerProviderStateMixin {
  final speedTest = FlutterInternetSpeedTest();
  late AnimationController _buttonAnimationController;

  TestStage _testStage = TestStage.idle;
  double _downloadRate = 0;
  double _uploadRate = 0;
  String _ping = '-';
  String _jitter = '-';
  String _isp = 'Press GO to start';

  @override
  void initState() {
    super.initState();
    // Controller for the pulsing "GO" button animation
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  void _startTest() {
    setState(() {
      _testStage = TestStage.download;
      _downloadRate = 0;
      _uploadRate = 0;
    });

    speedTest.startTesting(
      onStarted: () {
        setState(() => _isp = 'Connecting...');
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          if (data.type == TestType.download) {
            _testStage = TestStage.download;
            _downloadRate = data.transferRate;
          } else {
            _testStage = TestStage.upload;
            _uploadRate = data.transferRate;
          }
        });
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          _testStage = TestStage.complete;
          _downloadRate = download.transferRate;
          _uploadRate = upload.transferRate;
        });
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() => _testStage = TestStage.error);
      },
      onDefaultServerSelectionDone: (Client? client) {
        setState(() => _isp = client?.isp ?? 'Your ISP');
      },
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double displayRate = (_testStage == TestStage.download) ? _downloadRate : _uploadRate;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Speed Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(_getStageTitle(), style: const TextStyle(color: Colors.white70, fontSize: 18)),
            AnimatedGauge(
              speed: displayRate,
              isDownload: _testStage == TestStage.download,
            ),
            _buildStartButton(),
            _buildResultMetrics(),
          ],
        ),
      ),
    );
  }

  String _getStageTitle() {
    switch (_testStage) {
      case TestStage.download: return 'DOWNLOAD';
      case TestStage.upload: return 'UPLOAD';
      case TestStage.complete: return 'RESULTS';
      case TestStage.error: return 'Test Failed';
      default: return _isp;
    }
  }

  Widget _buildStartButton() {
    bool isTesting = _testStage == TestStage.download || _testStage == TestStage.upload;
    return GestureDetector(
      onTap: !isTesting ? _startTest : null,
      child: isTesting
          ? const SizedBox(height: 160) // Placeholder to maintain layout
          : FadeTransition(
              opacity: _buttonAnimationController.drive(CurveTween(curve: Curves.easeIn)),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('GO', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
    );
  }

  Widget _buildResultMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricItem(Icons.arrow_downward, 'Ping', _ping, 'ms'),
          _buildMetricItem(Icons.grain, 'Jitter', _jitter, 'ms'),
          _buildMetricItem(Icons.download_outlined, 'Download', _downloadRate.toStringAsFixed(2), 'Mbps'),
          _buildMetricItem(Icons.upload_outlined, 'Upload', _uploadRate.toStringAsFixed(2), 'Mbps'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String title, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text('$value $unit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

// Custom widget to handle smooth gauge animations
class AnimatedGauge extends StatefulWidget {
  final double speed;
  final bool isDownload;

  const AnimatedGauge({Key? key, required this.speed, required this.isDownload}) : super(key: key);

  @override
  _AnimatedGaugeState createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<AnimatedGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: widget.speed)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) {
      _animation = Tween<double>(begin: oldWidget.speed, end: widget.speed)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadGradient = const SweepGradient(colors: [Color(0xFF00C3FF), Color(0xFF00FFC2)]);
    final uploadGradient = const SweepGradient(colors: [Color(0xFFd946ef), Color(0xFFa21caf)]);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100, 
              showLabels: true,
              showTicks: true,
              showAxisLine: true,
              axisLabelStyle: const GaugeTextStyle(color: Colors.white70, fontSize: 12),
              labelsPosition: ElementsPosition.inside,
              ticksPosition: ElementsPosition.inside,
              majorTickStyle: const MajorTickStyle(length: 0.1, thickness: 2, color: Colors.white, lengthUnit: GaugeSizeUnit.factor),
              minorTickStyle: const MinorTickStyle(length: 0.05, thickness: 1, color: Colors.white, lengthUnit: GaugeSizeUnit.factor),
              minorTicksPerInterval: 4,
              interval: 10,
              startAngle: 180,
              endAngle: 0,
              axisLineStyle: AxisLineStyle(
                thickness: 0.15,
                cornerStyle: CornerStyle.bothCurve,
                color: Colors.grey[850],
                thicknessUnit: GaugeSizeUnit.factor,
              ),
              pointers: <GaugePointer>[
                RangePointer(
                  value: _animation.value,
                  cornerStyle: CornerStyle.bothCurve,
                  width: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                  gradient: widget.isDownload ? downloadGradient : uploadGradient,
                ),
                NeedlePointer(
                  value: _animation.value,
                  needleStartWidth: 1,
                  needleEndWidth: 5,
                  needleLength: 0.8,
                  knobStyle: const KnobStyle(knobRadius: 0.08, sizeUnit: GaugeSizeUnit.factor, color: Colors.white),
                )
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  // ****************** THE FINAL FIX ******************
                  // Replaced the Column with a single Text.rich widget
                  // to guarantee perfect alignment of the number and unit.
                  widget: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: _animation.value.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
                        ),
                        const TextSpan(
                          text: ' Mbps',
                          style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  angle: 90,
                  positionFactor: 0.4, // Adjusted position for better centering
                )
              ],
            ),
          ],
        );
      },
    );
  }
}

