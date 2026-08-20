package com.mapbanai.mapbanai

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.location.GnssStatus
import android.location.LocationManager
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val gnssChannel = "mapbanai/gnss"
    private val intentsChannel = "mapbanai/intents"
    private var lastInView = 0
    private var lastInUse = 0
    private var gnssListener: GnssStatus.Callback? = null
    private var pendingOpen: MethodChannel.Result? = null
    private var pendingOpenValue: String? = null

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

    // ── Open-with / deep link handling ─────────────────────────────────
    // Bridges an incoming VIEW intent (a .mbproj file opened from another
    // app, or a mapbanai://project/import?...) to Dart:
    //   * content:/file: URIs are copied into the cache dir and reported as
    //     a plain file path so Dart can read them without a plugin;
    //   * everything else (mapbanai://... links, https://...mbproj URLs) is
    //     reported as the raw string.

    private fun currentOpenPayload(): String? {
        val intent = intent
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val data = intent.data ?: return null
        return materializeOpen(data)
    }

    private fun materializeOpen(uri: Uri): String {
        if (uri.scheme == "content" || uri.scheme == "file") {
            val cached = copyToCache(uri)
            if (cached != null) return cached.absolutePath
        }
        return uri.toString()
    }

    /** Copies a readable content/file URI into the cache dir. */
    private fun copyToCache(uri: Uri): File? {
        var descriptor: ParcelFileDescriptor? = null
        var input: InputStream? = null
        try {
            descriptor = try {
                contentResolver.openFileDescriptor(uri, "r")
            } catch (e: Exception) {
                null
            }
            input = if (descriptor != null) {
                FileInputStream(descriptor.fileDescriptor)
            } else {
                contentResolver.openInputStream(uri) ?: return null
            }
            val dir = File(cacheDir, "shared")
            if (!dir.exists()) dir.mkdirs()
            val outFile = File(dir, queryDisplayName(uri) ?: "project.mbproj")
            val out = FileOutputStream(outFile)
            val buffer = ByteArray(64 * 1024)
            var read = input.read(buffer)
            while (read > 0) {
                out.write(buffer, 0, read)
                read = input.read(buffer)
            }
            out.close()
            return outFile
        } catch (e: Exception) {
            return null
        } finally {
            try { input?.close() } catch (e: Exception) {}
            try { descriptor?.close() } catch (e: Exception) {}
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = currentOpenPayload()
        if (payload != null) {
            if (pendingOpen != null) {
                pendingOpen?.success(mapOf("uri" to payload))
                pendingOpen = null
            } else {
                pendingOpenValue = payload
            }
        }
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            intentsChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialOpen" -> {
                    val payload = currentOpenPayload() ?: pendingOpenValue
                    pendingOpenValue = null
                    if (payload != null) {
                        result.success(mapOf("uri" to payload))
                    } else {
                        pendingOpen = result
                    }
                }
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