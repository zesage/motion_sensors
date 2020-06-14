import Flutter
import UIKit
import CoreMotion

let GRAVITY = 9.8;
let motionManager = CMMotionManager();

// translate from https://github.com/flutter/plugins/tree/master/packages/sensors
public class SwiftMotionSensorsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let ACCELEROMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/accelerometer"
        let GYROSCOPE_CHANNEL_NAME = "final.dev/plugins/motion_sensors/gyroscope"
        let USER_ACCELEROMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/user_accel"
        let MAGNETOMETER_CHANNEL_NAME = "final.dev/plugins/motion_sensors/magnetometer"
        let ORIENTATION_CHANNEL_NAME = "final.dev/plugins/motion_sensors/orientation"

        let accelerometerChannel = FlutterEventChannel(name: ACCELEROMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger());
        accelerometerChannel.setStreamHandler(AccelerometerStreamHandler());

        let userAccelerometerChannel = FlutterEventChannel(name: USER_ACCELEROMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger());
        userAccelerometerChannel.setStreamHandler(UserAccelerometerStreamHandler());

        let gyroscopeChannel = FlutterEventChannel(name: GYROSCOPE_CHANNEL_NAME, binaryMessenger: registrar.messenger());
        gyroscopeChannel.setStreamHandler(GyroscopeStreamHandler());

        let magnetometerChannel = FlutterEventChannel(name: MAGNETOMETER_CHANNEL_NAME, binaryMessenger: registrar.messenger());
        magnetometerChannel.setStreamHandler(MagnetometerStreamHandler());
        
        let orientationChannel = FlutterEventChannel(name: ORIENTATION_CHANNEL_NAME, binaryMessenger: registrar.messenger());
        orientationChannel.setStreamHandler(AttitudeStreamHandler());
    }
}

class AccelerometerStreamHandler: NSObject, FlutterStreamHandler {
    private let queue = OperationQueue();

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
            events([-data!.acceleration.x * GRAVITY, -data!.acceleration.y * GRAVITY, -data!.acceleration.z * GRAVITY]);
        }
        return nil;
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopAccelerometerUpdates();
        return nil;
    }
}

class UserAccelerometerStreamHandler: NSObject, FlutterStreamHandler {
    private let queue = OperationQueue();

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        motionManager.startDeviceMotionUpdates(to: queue) { (data, error) in
            events([-data!.userAcceleration.x * GRAVITY, -data!.userAcceleration.y * GRAVITY, -data!.userAcceleration.z * GRAVITY]);
        }
        return nil;
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates();
        return nil;
    }
}

class GyroscopeStreamHandler: NSObject, FlutterStreamHandler {
    private let queue = OperationQueue();

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        motionManager.startGyroUpdates(to: queue) { (data, error) in
            events([data!.rotationRate.x, data!.rotationRate.y, data!.rotationRate.z]);
        }
        return nil;
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopGyroUpdates();
        return nil;
    }
}

class MagnetometerStreamHandler: NSObject, FlutterStreamHandler {
    private let queue = OperationQueue();

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isDeviceMotionAvailable {
            motionManager.showsDeviceMovementDisplay = true;
            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: queue) { (data, error) in
                events([data!.magneticField.field.x, data!.magneticField.field.y, data!.magneticField.field.z]);
            }
        }
        return nil;
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        return nil;
    }
}

class AttitudeStreamHandler: NSObject, FlutterStreamHandler {
    private let queue = OperationQueue();
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xMagneticNorthZVertical, to: queue) { (data, error) in
                events([-data!.attitude.yaw, -data!.attitude.pitch, data!.attitude.roll]);
            }
        }
        return nil;
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        motionManager.stopDeviceMotionUpdates()
        return nil;
    }
}
