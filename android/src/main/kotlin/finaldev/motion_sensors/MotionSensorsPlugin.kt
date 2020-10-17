package finaldev.motion_sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.Registrar

// translate from https://github.com/flutter/plugins/tree/master/packages/sensors
/** MotionSensorsPlugin */
public class MotionSensorsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private val METHOD_CHANNEL_NAME = "motion_sensors/method"
  private val ACCELEROMETER_CHANNEL_NAME = "motion_sensors/accelerometer"
  private val GYROSCOPE_CHANNEL_NAME = "motion_sensors/gyroscope"
  private val USER_ACCELEROMETER_CHANNEL_NAME = "motion_sensors/user_accel"
  private val MAGNETOMETER_CHANNEL_NAME = "motion_sensors/magnetometer"
  private val ORIENTATION_CHANNEL_NAME = "motion_sensors/orientation"
  private val ABSOLUTE_ORIENTATION_CHANNEL_NAME = "motion_sensors/absolute_orientation"

  private var sensorManager: SensorManager? = null
  private var methodChannel: MethodChannel? = null
  private var accelerometerChannel: EventChannel? = null
  private var userAccelChannel: EventChannel? = null
  private var gyroscopeChannel: EventChannel? = null
  private var magnetometerChannel: EventChannel? = null
  private var orientationChannel: EventChannel? = null
  private var absoluteOrientationChannel: EventChannel? = null

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin = MotionSensorsPlugin()
      plugin.setupEventChannels(registrar.context(), registrar.messenger())
    }
  }

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    val context = binding.applicationContext
    setupEventChannels(context, binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    teardownEventChannels()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "isSensorAvailable" -> result.success(sensorManager!!.getSensorList(call.arguments as Int).isNotEmpty())
      else -> result.notImplemented()
    }
  }
  

  private fun setupEventChannels(context: Context, messenger: BinaryMessenger) {
    sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
    methodChannel!!.setMethodCallHandler(this)

    accelerometerChannel = EventChannel(messenger, ACCELEROMETER_CHANNEL_NAME)
    val accelerationStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_ACCELEROMETER)
    accelerometerChannel!!.setStreamHandler(accelerationStreamHandler)

    userAccelChannel = EventChannel(messenger, USER_ACCELEROMETER_CHANNEL_NAME)
    val linearAccelerationStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_LINEAR_ACCELERATION)
    userAccelChannel!!.setStreamHandler(linearAccelerationStreamHandler)

    gyroscopeChannel = EventChannel(messenger, GYROSCOPE_CHANNEL_NAME)
    val gyroScopeStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_GYROSCOPE)
    gyroscopeChannel!!.setStreamHandler(gyroScopeStreamHandler)

    magnetometerChannel = EventChannel(messenger, MAGNETOMETER_CHANNEL_NAME)
    val magnetometerStreamHandler = StreamHandlerImpl(sensorManager!!, Sensor.TYPE_MAGNETIC_FIELD)
    magnetometerChannel!!.setStreamHandler(magnetometerStreamHandler)

    orientationChannel = EventChannel(messenger, ORIENTATION_CHANNEL_NAME)
    val rotationVectorStreamHandler = RotationVectorStreamHandler(sensorManager!!, Sensor.TYPE_GAME_ROTATION_VECTOR)
    orientationChannel!!.setStreamHandler(rotationVectorStreamHandler)

    absoluteOrientationChannel = EventChannel(messenger, ABSOLUTE_ORIENTATION_CHANNEL_NAME)
    val absoluteOrientationStreamHandler = RotationVectorStreamHandler(sensorManager!!, Sensor.TYPE_ROTATION_VECTOR)
    absoluteOrientationChannel!!.setStreamHandler(absoluteOrientationStreamHandler)

  }

  private fun teardownEventChannels() {
    methodChannel!!.setMethodCallHandler(null)
    accelerometerChannel!!.setStreamHandler(null)
    userAccelChannel!!.setStreamHandler(null)
    gyroscopeChannel!!.setStreamHandler(null)
    magnetometerChannel!!.setStreamHandler(null)
    orientationChannel!!.setStreamHandler(null)
    absoluteOrientationChannel!!.setStreamHandler(null)
  }
}


class StreamHandlerImpl(private val sensorManager: SensorManager, private val sensorType: Int) :
        EventChannel.StreamHandler, SensorEventListener {
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    val sensor = sensorManager.getDefaultSensor(sensorType)
    sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    val sensorValues = listOf(event!!.values[0], event.values[1], event.values[2])
    eventSink?.success(sensorValues)
  }
}

class RotationVectorStreamHandler(private val sensorManager: SensorManager, private val sensorType: Int) :
        EventChannel.StreamHandler, SensorEventListener {
  private var eventSink: EventChannel.EventSink? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    val sensor = sensorManager.getDefaultSensor(sensorType)
    sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
  }

  override fun onCancel(arguments: Any?) {
    sensorManager.unregisterListener(this)
    eventSink = null
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {

  }

  override fun onSensorChanged(event: SensorEvent?) {
    var matrix = FloatArray(9)
    SensorManager.getRotationMatrixFromVector(matrix, event!!.values)
    var orientation = FloatArray(3)
    SensorManager.getOrientation(matrix, orientation)
    val sensorValues = listOf(-orientation[0], -orientation[1], orientation[2])
    eventSink?.success(sensorValues)
  }
}