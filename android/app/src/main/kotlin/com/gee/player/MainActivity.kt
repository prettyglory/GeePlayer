package com.gee.player

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.gee.player/media_library"
    private val permissionRequestCode = 4817
    private val scanExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> scanExecutor.execute {
                        try {
                            val access = accessResult()
                            val items = mutableListOf<Map<String, Any?>>()
                            if (access["videoAccess"] != "denied") {
                                items += queryMedia(isVideo = true)
                            }
                            if (access["audioAccess"] != "denied") {
                                items += queryMedia(isVideo = false)
                            }
                            mainHandler.post { result.success(access + mapOf("items" to items)) }
                        } catch (error: Exception) {
                            mainHandler.post {
                                result.error("media_scan_failed", error.message, null)
                            }
                        }
                    }
                    "requestAccess" -> requestMediaAccess(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasPermission(permission: String): Boolean =
        Build.VERSION.SDK_INT < 23 || checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun accessResult(): Map<String, String> {
        if (Build.VERSION.SDK_INT >= 34) {
            val video = when {
                hasPermission(Manifest.permission.READ_MEDIA_VIDEO) -> "granted"
                hasPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED) -> "limited"
                else -> "denied"
            }
            val audio = if (hasPermission(Manifest.permission.READ_MEDIA_AUDIO)) "granted" else "denied"
            return mapOf("videoAccess" to video, "audioAccess" to audio)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            return mapOf(
                "videoAccess" to if (hasPermission(Manifest.permission.READ_MEDIA_VIDEO)) "granted" else "denied",
                "audioAccess" to if (hasPermission(Manifest.permission.READ_MEDIA_AUDIO)) "granted" else "denied",
            )
        }
        val level = if (hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE)) "granted" else "denied"
        return mapOf("videoAccess" to level, "audioAccess" to level)
    }

    private fun requestMediaAccess(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("permission_in_progress", "A media permission request is already open.", null)
            return
        }

        val access = accessResult()
        val missing = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 34) {
            if (access["videoAccess"] != "granted") {
                missing += Manifest.permission.READ_MEDIA_VIDEO
                missing += Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            }
            if (access["audioAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_AUDIO
        } else if (Build.VERSION.SDK_INT >= 33) {
            if (access["videoAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_VIDEO
            if (access["audioAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_AUDIO
        } else if (access["videoAccess"] != "granted") {
            missing += Manifest.permission.READ_EXTERNAL_STORAGE
        }

        if (missing.isEmpty()) {
            result.success(access)
            return
        }
        pendingPermissionResult = result
        requestPermissions(missing.toTypedArray(), permissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            pendingPermissionResult?.success(accessResult())
            pendingPermissionResult = null
        }
    }

    private fun queryMedia(isVideo: Boolean): List<Map<String, Any?>> {
        val collection = if (isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val projection = mutableListOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.DATE_ADDED,
            if (isVideo) MediaStore.Video.Media.DURATION else MediaStore.Audio.Media.DURATION,
        )
        if (Build.VERSION.SDK_INT >= 29) {
            projection += MediaStore.MediaColumns.RELATIVE_PATH
        } else {
            projection += MediaStore.MediaColumns.DATA
        }
        if (!isVideo) projection += MediaStore.Audio.Media.ARTIST

        val items = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            collection,
            projection.toTypedArray(),
            null,
            null,
            "${MediaStore.MediaColumns.DATE_ADDED} DESC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val mimeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
            val dateIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_ADDED)
            val durationIndex = cursor.getColumnIndexOrThrow(
                if (isVideo) MediaStore.Video.Media.DURATION else MediaStore.Audio.Media.DURATION,
            )
            val pathIndex = cursor.getColumnIndexOrThrow(
                if (Build.VERSION.SDK_INT >= 29) MediaStore.MediaColumns.RELATIVE_PATH
                else MediaStore.MediaColumns.DATA,
            )
            val artistIndex = if (isVideo) -1 else cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex)
                val kind = if (isVideo) "video" else "audio"
                val rawPath = cursor.getStringOrNull(pathIndex).orEmpty()
                val folder = if (Build.VERSION.SDK_INT >= 29) {
                    rawPath.trimEnd('/').ifBlank { "Device storage" }
                } else {
                    rawPath.substringBeforeLast('/', "Device storage")
                }
                val duration = cursor.getLongOrNull(durationIndex)?.takeIf { it > 0 }
                val size = cursor.getLongOrNull(sizeIndex)?.takeIf { it >= 0 }
                val added = cursor.getLongOrNull(dateIndex)?.takeIf { it > 0 }?.times(1000)
                items += mapOf(
                    "id" to "$kind:$id",
                    "kind" to kind,
                    "uri" to ContentUris.withAppendedId(collection, id).toString(),
                    "fileName" to (cursor.getStringOrNull(nameIndex) ?: "Untitled"),
                    "folderPath" to folder,
                    "durationMs" to duration,
                    "sizeBytes" to size,
                    "dateAddedMs" to added,
                    "mimeType" to cursor.getStringOrNull(mimeIndex),
                    "artist" to if (artistIndex >= 0) cursor.getStringOrNull(artistIndex) else null,
                )
            }
        }
        return items
    }

    private fun Cursor.getStringOrNull(index: Int): String? =
        if (isNull(index)) null else getString(index)

    private fun Cursor.getLongOrNull(index: Int): Long? =
        if (isNull(index)) null else getLong(index)

    override fun onDestroy() {
        scanExecutor.shutdown()
        super.onDestroy()
    }
}
