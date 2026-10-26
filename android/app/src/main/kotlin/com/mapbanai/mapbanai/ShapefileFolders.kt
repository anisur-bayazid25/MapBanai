package com.mapbanai.mapbanai

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale
import java.util.concurrent.Executors

/** Reads only selected shapefiles' companions through user-granted SAF folders.
 * Android document grants do not grant direct java.io.File access to a path. */
class ShapefileFolders(private val activity: Activity, messenger: BinaryMessenger) {
    private val requestCode = 5194
    private val executor = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, "mapbanai/shapefile_folders")
    private var pending: MethodChannel.Result? = null
    private var pendingNames: Set<String> = emptySet()
    private val extensions = setOf("dbf", "shx", "prj", "cpg")
    private val limit = 64 * 1024 * 1024

    init {
        channel.setMethodCallHandler { call, result ->
            val names = (call.argument<List<String>>("names") ?: emptyList())
                .map { it.substringBeforeLast('.').lowercase(Locale.ROOT) }.toSet()
            when (call.method) {
                "readGranted" -> {
                    val origins = (call.argument<List<String>>("identifiers") ?: emptyList())
                        .mapNotNull { try { Uri.parse(it) } catch (_: Exception) { null } }
                    executor.execute {
                        val output = linkedMapOf<String, ByteArray>()
                        for (permission in activity.contentResolver.persistedUriPermissions) {
                            if (!permission.isReadPermission || !DocumentsContract.isTreeUri(permission.uri)) continue
                            val root = DocumentsContract.getTreeDocumentId(permission.uri)
                            val matching = origins.filter { uri ->
                                try {
                                    val id = DocumentsContract.getDocumentId(uri)
                                    uri.authority == permission.uri.authority &&
                                        id.substringBeforeLast('/', id.substringBefore(':') + ":").equals(root, true)
                                } catch (_: Exception) { false }
                            }.map { DocumentsContract.getDocumentId(it).substringAfterLast('/').substringAfter(':')
                                .substringBeforeLast('.').lowercase(Locale.ROOT) }.toSet().intersect(names)
                            if (matching.isEmpty()) continue
                            try { output.putAll(read(permission.uri, matching)) } catch (_: Exception) { /* Expired grant. */ }
                        }
                        activity.runOnUiThread { result.success(output) }
                    }
                }
                "chooseFolder" -> {
                    if (pending != null) {
                        result.error("busy", "A shapefile folder is already being selected.", null)
                    } else {
                        pending = result
                        pendingNames = names
                        try {
                            activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                            }, requestCode)
                        } catch (error: Exception) {
                            pending = null
                            result.error("folder_picker", "Could not open the folder picker.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun read(tree: Uri, names: Set<String>): Map<String, ByteArray> {
        val resolver = activity.contentResolver
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val output = linkedMapOf<String, ByteArray>()
        var total = 0
        resolver.query(children, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val name = cursor.getString(1) ?: continue
                if (name.substringBeforeLast('.').lowercase(Locale.ROOT) !in names ||
                    name.substringAfterLast('.').lowercase(Locale.ROOT) !in extensions) continue
                val uri = DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))
                resolver.openInputStream(uri)?.use { input ->
                    val bytes = ByteArrayOutputStream()
                    val buffer = ByteArray(16384)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        total += count
                        require(total <= limit) { "Companion files exceed 64 MB." }
                        bytes.write(buffer, 0, count)
                    }
                    output[name] = bytes.toByteArray()
                }
            }
        }
        return output
    }

    fun onActivityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code != requestCode) return false
        val result = pending ?: return true
        val names = pendingNames
        pending = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
            return true
        }
        try {
            activity.contentResolver.takePersistableUriPermission(tree,
                Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) { /* The current temporary grant still works. */ }
        executor.execute {
            try {
                val files = read(tree, names)
                activity.runOnUiThread { result.success(files) }
            } catch (error: Exception) {
                activity.runOnUiThread { result.error("folder_read", "Could not read shapefile companions: ${error.message}", null) }
            }
        }
        return true
    }

    fun close() {
        channel.setMethodCallHandler(null)
        executor.shutdownNow()
        pending?.success(null)
        pending = null
    }
}
