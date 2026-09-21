package com.gee.player

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.app.PictureInPictureParams
import android.content.Context
import android.media.MediaMetadataRetriever
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "com.gee.player/media_library"
    private val controlsChannelName = "com.gee.player/player_controls"
    private val permissionRequestCode = 4817
    private val scanExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var playbackDescriptor: ParcelFileDescriptor? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getVolume" -> {
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val maximum = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val current = audio.getStreamVolume(AudioManager.STREAM_MUSIC)
                        result.success(if (maximum == 0) 0.0 else current.toDouble() / maximum)
                    }
                    "setVolume" -> {
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val maximum = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val value = (call.argument<Double>("value") ?: 0.0).coerceIn(0.0, 1.0)
                        audio.setStreamVolume(
                            AudioManager.STREAM_MUSIC,
                            (value * maximum).toInt(),
                            0,
                        )
                        result.success(null)
                    }
                    "getBrightness" -> {
                        val windowValue = window.attributes.screenBrightness
                        val value = if (windowValue >= 0f) {
                            windowValue.toDouble()
                        } else {
                            try {
                                Settings.System.getInt(
                                    contentResolver,
                                    Settings.System.SCREEN_BRIGHTNESS,
                                ) / 255.0
                            } catch (_: Exception) {
                                0.5
                            }
                        }
                        result.success(value.coerceIn(0.0, 1.0))
                    }
                    "setBrightness" -> {
                        val value = (call.argument<Double>("value") ?: 0.5)
                            .coerceIn(0.01, 1.0)
                        val attributes = window.attributes
                        attributes.screenBrightness = value.toFloat()
                        window.attributes = attributes
                        result.success(null)
                    }
                    "enterPictureInPicture" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        ) {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            result.success(enterPictureInPictureMode(params))
                        } else {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
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
                    "requestAccess" -> requestMediaAccess(
                        result,
                        call.argument<String>("kind") ?: "both",
                    )
                    "artwork" -> scanExecutor.execute {
                        val bytes = try {
                            loadArtwork(
                                call.argument<String>("uri"),
                                call.argument<String>("kind"),
                            )
                        } catch (error: Exception) {
                            null
                        }
                        mainHandler.post { result.success(bytes) }
                    }
                    "findCompanionSubtitle" -> scanExecutor.execute {
                        val found = try {
                            findCompanionSubtitle(
                                call.argument<String>("folderPath"),
                                call.argument<String>("fileName"),
                                call.argument<List<String>>("languages") ?: listOf("SW", "EN"),
                            )
                        } catch (_: Exception) {
                            null
                        }
                        mainHandler.post { result.success(found) }
                    }
                    "openSettings" -> {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:$packageName"),
                                ),
                            )
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("settings_unavailable", error.message, null)
                        }
                    }
                    "openPlayback" -> {
                        try {
                            val uri = Uri.parse(call.argument<String>("uri"))
                            require(uri.scheme == "content" && uri.authority == "media") {
                                "Expected a MediaStore content URI."
                            }
                            playbackDescriptor?.close()
                            playbackDescriptor = null
                            playbackDescriptor = contentResolver.openFileDescriptor(uri, "r")
                                ?: throw IllegalStateException("Unable to open media file.")
                            result.success("fd://${playbackDescriptor!!.fd}")
                        } catch (error: Exception) {
                            result.error("playback_open_failed", error.message, null)
                        }
                    }
                    "closePlayback" -> {
                        try {
                            playbackDescriptor?.close()
                            playbackDescriptor = null
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("playback_close_failed", error.message, null)
                        }
                    }
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

    private fun requestMediaAccess(result: MethodChannel.Result, kind: String) {
        if (pendingPermissionResult != null) {
            result.error("permission_in_progress", "A media permission request is already open.", null)
            return
        }

        val access = accessResult()
        val missing = mutableListOf<String>()
        val needsVideo = kind == "video" || kind == "both"
        val needsAudio = kind == "audio" || kind == "both"
        if (Build.VERSION.SDK_INT >= 34) {
            if (needsVideo && access["videoAccess"] != "granted") {
                missing += Manifest.permission.READ_MEDIA_VIDEO
                missing += Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED
            }
            if (needsAudio && access["audioAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_AUDIO
        } else if (Build.VERSION.SDK_INT >= 33) {
            if (needsVideo && access["videoAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_VIDEO
            if (needsAudio && access["audioAccess"] != "granted") missing += Manifest.permission.READ_MEDIA_AUDIO
        } else if ((needsVideo || needsAudio) && access["videoAccess"] != "granted") {
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

    private fun findCompanionSubtitle(
        folderPath: String?,
        fileName: String?,
        languages: List<String>,
    ): Map<String, Any?>? {
        if (folderPath.isNullOrBlank() || fileName.isNullOrBlank() || folderPath == "Device storage") return null
        val baseName = fileName.substringBeforeLast('.', fileName)
        val candidates = mutableListOf<Pair<String, Uri>>()
        if (Build.VERSION.SDK_INT >= 29) {
            val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
            val relativePath = folderPath.trimEnd('/') + "/"
            contentResolver.query(
                collection,
                arrayOf(
                    MediaStore.Files.FileColumns._ID,
                    MediaStore.Files.FileColumns.DISPLAY_NAME,
                    MediaStore.Files.FileColumns.SIZE,
                ),
                "${MediaStore.Files.FileColumns.RELATIVE_PATH} = ?",
                arrayOf(relativePath),
                null,
            )?.use { cursor ->
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                while (cursor.moveToNext()) {
                    val name = cursor.getStringOrNull(nameIndex) ?: continue
                    val size = cursor.getLongOrNull(sizeIndex) ?: continue
                    if (size <= 0 || size > 4L * 1024 * 1024) continue
                    if (companionRank(baseName, name, languages) == null) continue
                    candidates += name to ContentUris.withAppendedId(collection, cursor.getLong(idIndex))
                }
            }
        } else {
            File(folderPath).listFiles()?.forEach { file ->
                if (file.isFile && file.length() in 1L..(4L * 1024 * 1024) &&
                    companionRank(baseName, file.name, languages) != null) {
                    candidates += file.name to Uri.fromFile(file)
                }
            }
        }
        candidates.sortBy { companionRank(baseName, it.first, languages) }
        for ((name, uri) in candidates) {
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        if (output.size() + read > 4 * 1024 * 1024) return@use null
                        output.write(buffer, 0, read)
                    }
                    output.toByteArray()
                }
                if (bytes != null && bytes.isNotEmpty()) return mapOf("name" to name, "bytes" to bytes)
            } catch (_: Exception) {
                // An indexed document can still be unreadable under scoped storage.
            }
        }
        return null
    }

    private fun companionRank(baseName: String, subtitleName: String, languages: List<String>): Int? {
        val extension = subtitleName.substringAfterLast('.', "").lowercase()
        if (extension !in setOf("srt", "vtt", "ass", "ssa", "sub")) return null
        val stem = subtitleName.substringBeforeLast('.')
        if (stem.equals(baseName, ignoreCase = true)) return languages.size
        if (!stem.startsWith("$baseName.", ignoreCase = true)) return null
        val suffix = stem.substring(baseName.length + 1).lowercase()
        val code = when (suffix) {
            "sw", "swa", "swahili", "kiswahili" -> "SW"
            "en", "eng", "english" -> "EN"
            else -> return null
        }
        return languages.indexOf(code).takeIf { it >= 0 }
    }

    private fun loadArtwork(uriText: String?, kind: String?): ByteArray? {
        if (uriText == null) return null
        val uri = Uri.parse(uriText)
        if (uri.scheme != "content") return null

        val bitmap = when (kind) {
            "video" -> {
                if (Build.VERSION.SDK_INT >= 29) {
                    contentResolver.loadThumbnail(uri, Size(160, 160), null)
                } else {
                    val id = uri.lastPathSegment?.toLongOrNull() ?: return null
                    MediaStore.Video.Thumbnails.getThumbnail(
                        contentResolver,
                        id,
                        MediaStore.Video.Thumbnails.MINI_KIND,
                        null,
                    )
                }
            }
            "audio" -> {
                val retriever = MediaMetadataRetriever()
                try {
                    retriever.setDataSource(this, uri)
                    val art = retriever.embeddedPicture ?: return null
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(art, 0, art.size, bounds)
                    var sample = 1
                    while (bounds.outWidth / sample > 160 || bounds.outHeight / sample > 160) {
                        sample *= 2
                    }
                    val options = BitmapFactory.Options().apply { inSampleSize = sample }
                    BitmapFactory.decodeByteArray(art, 0, art.size, options)
                } finally {
                    retriever.release()
                }
            }
            else -> return null
        } ?: return null

        return ByteArrayOutputStream().use { output ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 78, output)
            bitmap.recycle()
            output.toByteArray()
        }
    }

    override fun onDestroy() {
        playbackDescriptor?.close()
        playbackDescriptor = null
        scanExecutor.shutdown()
        super.onDestroy()
    }
}
