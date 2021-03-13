import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

final MotionSensors motionSensors = MotionSensors();
const MethodChannel _methodChannel = MethodChannel('motion_sensors/method');
const EventChannel _accelerometerEventChannel = EventChannel('motion_sensors/accelerometer');
const EventChannel _gyroscopeEventChannel = EventChannel('motion_sensors/gyroscope');
const EventChannel _magnetometerEventChannel = EventChannel('motion_sensors/magnetometer');
const EventChannel _userAccelerometerEventChannel = EventChannel('motion_sensors/user_accelerometer');
const EventChannel _orientationChannel = EventChannel('motion_sensors/orientation');
const EventChannel _absoluteOrientationChannel = EventChannel('motion_sensors/absolute_orientation');
const EventChannel _screenOrientationChannel = EventChannel('motion_sensors/screen_orientation');

// from https://github.com/flutter/plugins/tree/master/packages/sensors
/// Discrete reading from an accelerometer. Accelerometers measure the velocity
/// of the device. Note that these readings include the effects of gravity. Put
/// simply, you can use accelerometer readings to tell if the device is moving in
/// a particular direction.
class AccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  AccelerometerEvent(this.x, this.y, this.z);
  AccelerometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Acceleration force along the x axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (including gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  @override
  String toString() => '[AccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class MagnetometerEvent {
  MagnetometerEvent(this.x, this.y, this.z);
  MagnetometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  final double x;
  final double y;
  final double z;
  @override
  String toString() => '[Magnetometer (x: $x, y: $y, z: $z)]';
}

/// Discrete reading from a gyroscope. Gyroscopes measure the rate or rotation of
/// the device in 3D space.
class GyroscopeEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  GyroscopeEvent(this.x, this.y, this.z);
  GyroscopeEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Rate of rotation around the x axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "pitch". The top of the device will tilt towards or away from the
  /// user as this value changes.
  final double x;

  /// Rate of rotation around the y axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "yaw". The lengthwise edge of the device will rotate towards or away from
  /// the user as this value changes.
  final double y;

  /// Rate of rotation around the z axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "roll". When this changes the face of the device should remain facing
  /// forward, but the orientation will change from portrait to landscape and so
  /// on.
  final double z;

  @override
  String toString() => '[GyroscopeEvent (x: $x, y: $y, z: $z)]';
}

/// Like [AccelerometerEvent], this is a discrete reading from an accelerometer
/// and measures the velocity of the device. However, unlike
/// [AccelerometerEvent], this event does not include the effects of gravity.
class UserAccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  UserAccelerometerEvent(this.x, this.y, this.z);
  UserAccelerometerEvent.fromList(List<double> list)
      : x = list[0],
        y = list[1],
        z = list[2];

  /// Acceleration force along the x axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (excluding gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  @override
  String toString() => '[UserAccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class OrientationEvent {
  OrientationEvent(this.yaw, this.pitch, this.roll);
  OrientationEvent.fromList(List<double> list)
      : yaw = list[0],
        pitch = list[1],
        roll = list[2];

  /// The yaw of the device in radians.
  final double yaw;

  /// The pitch of the device in radians.
  final double pitch;

  /// The roll of the device in radians.
  final double roll;
  @override
  String toString() => '[Orientation (yaw: $yaw, pitch: $pitch, roll: $roll)]';
}

class AbsoluteOrientationEvent {
  AbsoluteOrientationEvent(this.yaw, this.pitch, this.roll);
  AbsoluteOrientationEvent.fromList(List<double> list)
      : yaw = list[0],
        pitch = list[1],
        roll = list[2];

  /// The yaw of the device in radians.
  final double yaw;

  /// The pitch of the device in radians.
  final double pitch;

  /// The roll of the device in radians.
  final double roll;
  @override
  String toString() => '[Orientation (yaw: $yaw, pitch: $pitch, roll: $roll)]';
}

class ScreenOrientationEvent {
  ScreenOrientationEvent(this.angle);

  /// The screen's current orientation angle. The angle may be 0, 90, 180, -90 degrees
  final double? angle;

  @override
  String toString() => '[ScreenOrientation (angle: $angle)]';
}

class MotionSensors {
  Stream<AccelerometerEvent>? _accelerometerEvents;
  Stream<GyroscopeEvent>? _gyroscopeEvents;
  Stream<UserAccelerometerEvent>? _userAccelerometerEvents;
  Stream<MagnetometerEvent>? _magnetometerEvents;
  Stream<OrientationEvent>? _orientationEvents;
  Stream<AbsoluteOrientationEvent>? _absoluteOrientationEvents;
  Stream<ScreenOrientationEvent>? _screenOrientationEvents;
  OrientationEvent? _initialOrientation;

  static const int TYPE_ACCELEROMETER = 1;
  static const int TYPE_MAGNETIC_FIELD = 2;
  static const int TYPE_GYROSCOPE = 4;
  static const int TYPE_USER_ACCELEROMETER = 10;
  static const int TYPE_ORIENTATION = 15; //=TYPE_GAME_ROTATION_VECTOR
  static const int TYPE_ABSOLUTE_ORIENTATION = 11; //=TYPE_ROTATION_VECTOR

  /// Determines whether sensor is available.
  Future<bool> isSensorAvailable(int sensorType) async {
    final available = await _methodChannel.invokeMethod('isSensorAvailable', sensorType);
    return available;
  }

  /// Determines whether accelerometer is available.
  Future<bool> isAccelerometerAvailable() => isSensorAvailable(TYPE_ACCELEROMETER);

  /// Determines whether magnetometer is available.
  Future<bool> isMagnetometerAvailable() => isSensorAvailable(TYPE_MAGNETIC_FIELD);

  /// Determines whether gyroscope is available.
  Future<bool> isGyroscopeAvailable() => isSensorAvailable(TYPE_GYROSCOPE);

  /// Determines whether user accelerometer is available.
  Future<bool> isUserAccelerationAvailable() => isSensorAvailable(TYPE_USER_ACCELEROMETER);

  /// Determines whether orientation is available.
  Future<bool> isOrientationAvailable() => isSensorAvailable(TYPE_ORIENTATION);

  /// Determines whether absolute orientation is available.
  Future<bool> isAbsoluteOrientationAvailable() => isSensorAvailable(TYPE_ABSOLUTE_ORIENTATION);

  /// Change the update interval of sensor. The units are in microseconds.
  Future setSensorUpdateInterval(int sensorType, int interval) async {
    await _methodChannel.invokeMethod('setSensorUpdateInterval', {"sensorType": sensorType, "interval": interval});
  }

  /// The update interval of accelerometer. The units are in microseconds.
  set accelerometerUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_ACCELEROMETER, interval);

  /// The update interval of magnetometer. The units are in microseconds.
  set magnetometerUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_MAGNETIC_FIELD, interval);

  /// The update interval of Gyroscope. The units are in microseconds.
  set gyroscopeUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_GYROSCOPE, interval);

  /// The update interval of user accelerometer. The units are in microseconds.
  set userAccelerometerUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_USER_ACCELEROMETER, interval);

  /// The update interval of orientation. The units are in microseconds.
  set orientationUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_ORIENTATION, interval);

  /// The update interval of absolute orientation. The units are in microseconds.
  set absoluteOrientationUpdateInterval(int interval) => setSensorUpdateInterval(TYPE_ABSOLUTE_ORIENTATION, interval);

  /// A broadcast stream of events from the device accelerometer.
  Stream<AccelerometerEvent> get accelerometer {
    if (_accelerometerEvents == null) {
      _accelerometerEvents = _accelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => AccelerometerEvent.fromList(event.cast<double>()));
    }
    return _accelerometerEvents!;
  }

  /// A broadcast stream of events from the device gyroscope.
  Stream<GyroscopeEvent> get gyroscope {
    if (_gyroscopeEvents == null) {
      _gyroscopeEvents = _gyroscopeEventChannel.receiveBroadcastStream().map((dynamic event) => GyroscopeEvent.fromList(event.cast<double>()));
    }
    return _gyroscopeEvents!;
  }

  /// Events from the device accelerometer with gravity removed.
  Stream<UserAccelerometerEvent> get userAccelerometer {
    if (_userAccelerometerEvents == null) {
      _userAccelerometerEvents = _userAccelerometerEventChannel.receiveBroadcastStream().map((dynamic event) => UserAccelerometerEvent.fromList(event.cast<double>()));
    }
    return _userAccelerometerEvents!;
  }

  /// A broadcast stream of events from the device magnetometer.
  Stream<MagnetometerEvent> get magnetometer {
    if (_magnetometerEvents == null) {
      _magnetometerEvents = _magnetometerEventChannel.receiveBroadcastStream().map((dynamic event) => MagnetometerEvent.fromList(event.cast<double>()));
    }
    return _magnetometerEvents!;
  }

  /// The current orientation of the device.
  Stream<OrientationEvent> get orientation {
    if (_orientationEvents == null) {
      _orientationEvents = _orientationChannel.receiveBroadcastStream().map((dynamic event) {
        var orientation = OrientationEvent.fromList(event.cast<double>());
        _initialOrientation ??= orientation;
        // Change the initial yaw of the orientation to zero
        var yaw = (orientation.yaw + math.pi - _initialOrientation!.yaw) % (math.pi * 2) - math.pi;
        return OrientationEvent(yaw, orientation.pitch, orientation.roll);
      });
    }
    return _orientationEvents!;
  }

  /// The current absolute orientation of the device.
  Stream<AbsoluteOrientationEvent> get absoluteOrientation {
    if (_absoluteOrientationEvents == null) {
      _absoluteOrientationEvents = _absoluteOrientationChannel.receiveBroadcastStream().map((dynamic event) => AbsoluteOrientationEvent.fromList(event.cast<double>()));
    }
    return _absoluteOrientationEvents!;
  }

  /// The rotation of the screen from its "natural" orientation.
  Stream<ScreenOrientationEvent> get screenOrientation {
    if (_screenOrientationEvents == null) {
      _screenOrientationEvents = _screenOrientationChannel.receiveBroadcastStream().map((dynamic event) => ScreenOrientationEvent(event as double?));
    }
    return _screenOrientationEvents!;
  }

  Matrix4 getRotationMatrix(Vector3 gravity, Vector3 geomagnetic) {
    Vector3 a = gravity.normalized();
    Vector3 e = geomagnetic.normalized();
    Vector3 h = e.cross(a).normalized();
    Vector3 m = a.cross(h).normalized();
    return Matrix4(
      h.x, m.x, a.x, 0, //
      h.y, m.y, a.y, 0,
      h.z, m.z, a.z, 0,
      0, 0, 0, 1,
    );
  }

  Vector3 getOrientation(Matrix4 m) {
    final r = m.storage;
    return Vector3(
      math.atan2(-r[4], r[5]),
      math.asin(r[6]),
      math.atan2(-r[2], r[10]),
    );
  }
}
