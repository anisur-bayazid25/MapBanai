package com.mapbanai.mapbanai

import android.annotation.SuppressLint
import android.content.Context
import android.location.GnssStatus
import android.location.LocationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val gnssChannel = "mapbanai/gnss"
    private var lastInView = 0
    private var lastInUse = 0
    private var gnssListener: GnssStatus.Callback? = null

    @SuppressLint("MissingPermission")
    private fun ensureGnssListener(lm: LocationManager) {
        if (gnssListener != null) return
        val listener: GnssStatus.Callback = object : GnssStatus.Callback() {
            override fun onSatelliteStatusChanged(status: GnssStatus) {
                lastInView = status.satelliteCount
                var inUse = 0
                for (i in 0 until status.satelliteCount) {
                    if (status.usedInFix(i)) inUse++
                }
                lastInUse = inUse
            }
        }
        try {
            if (lm.allProviders.contains(LocationManager.GPS_PROVIDER) &&
                lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
            ) {
                lm.registerGnssStatusCallback(listener)
                gnssListener = listener
            }
        } catch (e: SecurityException) {
            // No location permission yet; fall back to the GPS snapshot below.
        }
    }

    @SuppressLint("MissingPermission")
    private fun reportSatellites(result: MethodChannel.Result) {
        val lm = applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            if (gnssListener == null) {
                ensureGnssListener(lm)
                val status = lm.getGpsStatus(null)
                if (status != null) {
                    val satellites = status.satellites
                    if (satellites != null) {
                        var inView = 0
                        var inUse = 0
                        val iterator = satellites.iterator()
                        while (iterator.hasNext()) {
                            val sat = iterator.next()
                            inView++
                            if (sat.usedInFix()) inUse++
                        }
                        lastInView = inView
                        lastInUse = inUse
                    }
                }
            }
        } catch (e: Exception) {
            // Keep the last snapshot.
        }
        result.success(mapOf("inView" to lastInView, "inUse" to lastInUse))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            gnssChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSatellites" -> reportSatellites(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        val listener = gnssListener
        if (listener != null) {
            val lm = applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            try {
                lm.unregisterGnssStatusCallback(listener)
            } catch (e: Exception) {
                // Ignore.
            }
            gnssListener = null
        }
        super.onDestroy()
    }
}