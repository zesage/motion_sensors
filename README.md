# motion_sensors

[![pub package](https://img.shields.io/pub/v/motion_sensors.svg)](https://pub.dev/packages/motion_sensors)

Flutter plugin for accessing the Android and iOS accelerometer, gyroscope, magnetometer and orientation sensors.

## Getting Started

To use this plugin, add `motion_sensors` as a [dependency in your pubspec.yaml
file](https://flutter.io/platform-plugins/).

```yaml
dependencies:
  motion_sensors: ^0.1.0
```

Import to your project.

``` dart
import 'package:motion_sensors/motion_sensors.dart';

motionSensors.magnetometer.listen((MagnetometerEvent event) {
    print(event);
});

```

## Screenshot

<img src="https://github.com/zesage/motion_sensors/raw/master/screenshot.png" width="30%" />