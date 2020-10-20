# motion_sensors

Flutter plugin for accessing the Android and iOS accelerometer, gyroscope, magnetometer and orientation sensors.

## Getting Started

To use this plugin, add `motion_sensors` as a [dependency in your pubspec.yaml
file](https://flutter.io/platform-plugins/).

``` dart
import 'package:motion_sensors/motion_sensors.dart';

motionSensors.magnetometer.listen((MagnetometerEvent event) {
    print(event);
});

```

## Screenshot

![screenshot](https://github.com/zesage/motion_sensors/raw/master/screenshot.png)
