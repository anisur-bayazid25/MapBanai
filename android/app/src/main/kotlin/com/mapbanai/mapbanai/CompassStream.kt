package com.mapbanai.mapbanai

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.plugin.common.EventChannel

/** Foreground-only magnetic compass. GPS bearing remains a separate travel direction. */
class CompassStream(private val activity: MainActivity) : EventChannel.StreamHandler, SensorEventListener {
    private val manager = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        ?: manager.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
    private var sink: EventChannel.EventSink? = null
    private var resumed = true
    private var lastSent = 0L
    private val rotation = FloatArray(9)
    private val adjusted = FloatArray(9)
    private val orientation = FloatArray(3)
    private var accuracy = SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        if (sensor == null) events.success(mapOf("available" to false)) else resume()
    }
    override fun onCancel(arguments: Any?) { manager.unregisterListener(this); sink = null }
    fun pause() { resumed = false; manager.unregisterListener(this) }
    fun resume() {
        resumed = true
        if (sink != null && sensor != null) {
            lastSent = 0L
            if (!manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME))
                sink?.success(mapOf("available" to false))
        }
    }
    override fun onAccuracyChanged(sensor: Sensor?, value: Int) { accuracy = value }
    @Suppress("DEPRECATION")
    override fun onSensorChanged(event: SensorEvent) {
        if (!resumed || sink == null || event.timestamp - lastSent < 50_000_000L) return
        lastSent = event.timestamp
        SensorManager.getRotationMatrixFromVector(rotation, event.values)
        val axes = when (activity.windowManager.defaultDisplay.rotation) {
            Surface.ROTATION_90 -> Pair(SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X)
            Surface.ROTATION_180 -> Pair(SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y)
            Surface.ROTATION_270 -> Pair(SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X)
            else -> Pair(SensorManager.AXIS_X, SensorManager.AXIS_Y)
        }
        SensorManager.remapCoordinateSystem(rotation, axes.first, axes.second, adjusted)
        SensorManager.getOrientation(adjusted, orientation)
        val heading = (Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0
        sink?.success(mapOf("available" to true, "heading" to heading, "accuracy" to accuracy))
    }
}
