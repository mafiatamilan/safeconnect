// lib/screens/speed_test_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart'; // Correct import

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

  @override
  _SpeedTestPageState createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  // Use the new speed test object
  final speedTest = FlutterInternetSpeedTest();

  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  bool _isTesting = false;

  String _unitText = 'Mbps'; // To hold the unit (Mbps or Kbps)

  // This is the corrected test logic
  void _startTest() {
    setState(() {
      _isTesting = true;
    });

    speedTest.startTesting(
      onStarted: () {
        setState(() {
          _downloadRate = 0;
          _uploadRate = 0;
          _downloadProgress = '0';
          _uploadProgress = '0';
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps'; // <-- CORRECT

          if (data.type == TestType.download) {
            _downloadRate = data.transferRate;
            _downloadProgress = percent.toStringAsFixed(2);
          } else {
            _uploadRate = data.transferRate;
            _uploadProgress = percent.toStringAsFixed(2);
          }
        });
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          _downloadRate = download.transferRate;
          _uploadRate = upload.transferRate;
          _isTesting = false;
        });
      },
      onError: (String errorMessage, String speedTestError) {
        if (mounted) {
          setState(() {
            _isTesting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speed test failed: $errorMessage')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Network Speed Test")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Download Speed', style: TextStyle(fontSize: 18)),
              SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    pointers: <GaugePointer>[NeedlePointer(value: _downloadRate, enableAnimation: true)],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text('${_downloadRate.toStringAsFixed(2)} $_unitText', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        angle: 90,
                        positionFactor: 0.7,
                      )
                    ],
                  ),
                ],
              ),
              Text('Progress: $_downloadProgress%'),
              const SizedBox(height: 30),
              const Text('Upload Speed', style: TextStyle(fontSize: 18)),
              SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    pointers: <GaugePointer>[NeedlePointer(value: _uploadRate, enableAnimation: true)],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text('${_uploadRate.toStringAsFixed(2)} $_unitText', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        angle: 90,
                        positionFactor: 0.7,
                      )
                    ],
                  ),
                ],
              ),
              Text('Progress: $_uploadProgress%'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isTesting ? null : _startTest, // Call the corrected method
                child: Text(_isTesting ? 'Testing...' : 'Start Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

