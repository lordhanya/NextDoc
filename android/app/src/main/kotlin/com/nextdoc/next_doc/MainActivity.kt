package com.nextdoc.next_doc

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "NextDocSave"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.nextdoc.next_doc/downloads"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val toolFolder = call.argument<String>("toolFolder")

                    if (sourcePath == null || fileName == null || toolFolder == null) {
                        Log.e(TAG, "Missing required arguments: sourcePath=$sourcePath, fileName=$fileName, toolFolder=$toolFolder")
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }

                    saveToDownloads(sourcePath, fileName, toolFolder, result)
                }
                "saveToDownloadsLegacy" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val toolFolder = call.argument<String>("toolFolder")

                    if (sourcePath == null || fileName == null || toolFolder == null) {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }

                    saveToDownloadsLegacy(sourcePath, fileName, toolFolder, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Primary: MediaStore (Android 10+, user-visible in Downloads) ──────────

    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        toolFolder: String,
        result: MethodChannel.Result,
    ) {
        try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) {
                Log.e(TAG, "Source file not found: $sourcePath")
                result.error("FILE_NOT_FOUND", "Source file not found: $sourcePath", null)
                return
            }

            Log.d(TAG, "saveToDownloads: source=$sourcePath, name=$fileName, folder=$toolFolder")
            Log.d(TAG, "Source file exists: ${sourceFile.exists()}, size: ${sourceFile.length()}")

            val mimeType = when {
                fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") -> "image/jpeg"
                fileName.endsWith(".png") -> "image/png"
                fileName.endsWith(".gif") -> "image/gif"
                else -> "application/pdf"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val relativePath = "NextDoc/$toolFolder/"
                Log.d(TAG, "Attempting MediaStore insert: relativePath=$relativePath, mimeType=$mimeType")

                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                    put(MediaStore.Downloads.TITLE, fileName.substringBeforeLast("."))
                    put(MediaStore.Downloads.OWNER_PACKAGE_NAME, "com.nextdoc.next_doc")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }

                // Attempt 1: standard Downloads URI
                var uri: Uri? = tryInsert(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues
                )

                // Attempt 2: explicit external primary volume (fixes Samsung/Xiaomi)
                if (uri == null) {
                    Log.w(TAG, "MediaStore.Downloads.EXTERNAL_CONTENT_URI returned null, trying getContentUri")
                    uri = tryInsert(
                        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                        contentValues
                    )
                }

                // Attempt 3: fallback to Files URI with same RELATIVE_PATH
                if (uri == null) {
                    Log.w(TAG, "Downloads URI failed, trying MediaStore.Files")
                    uri = tryInsert(
                        MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY),
                        contentValues
                    )
                }

                if (uri != null) {
                    Log.d(TAG, "MediaStore insert succeeded: $uri")

                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        sourceFile.inputStream().use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }

                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(uri, contentValues, null, null)

                    sourceFile.delete()
                    Log.d(TAG, "File saved successfully via MediaStore")

                    result.success(uri.toString())
                    return
                }

                Log.e(TAG, "All MediaStore insert attempts returned null")
            }

            // Fallback: legacy public directory (Android ≤ 10 with requestLegacyExternalStorage)
            Log.d(TAG, "Falling back to legacy DIRECTORY_DOWNLOADS path")
            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val targetDir = File(downloadsDir, "NextDoc/$toolFolder")
            targetDir.mkdirs()

            val targetFile = resolveCollision(targetDir, fileName)
            sourceFile.copyTo(targetFile, overwrite = false)
            sourceFile.delete()

            Log.d(TAG, "File saved via legacy path: ${targetFile.absolutePath}")
            result.success(targetFile.absolutePath)

        } catch (e: Exception) {
            Log.e(TAG, "saveToDownloads exception: ${e.message}", e)
            result.error("SAVE_FAILED", "Failed to save: ${e.message}", null)
        }
    }

    private fun tryInsert(uri: Uri, values: ContentValues): Uri? {
        return try {
            contentResolver.insert(uri, values)
        } catch (e: Exception) {
            Log.e(TAG, "Insert failed for $uri: ${e.message}")
            null
        }
    }

    // ── Secondary: direct legacy path (Android ≤ 10) ─────────────────────────

    private fun saveToDownloadsLegacy(
        sourcePath: String,
        fileName: String,
        toolFolder: String,
        result: MethodChannel.Result,
    ) {
        try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) {
                result.error("FILE_NOT_FOUND", "Source file not found", null)
                return
            }

            Log.d(TAG, "saveToDownloadsLegacy: source=$sourcePath, name=$fileName, folder=$toolFolder")

            val downloadsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val targetDir = File(downloadsDir, "NextDoc/$toolFolder")
            targetDir.mkdirs()

            val targetFile = resolveCollision(targetDir, fileName)
            sourceFile.copyTo(targetFile, overwrite = false)
            sourceFile.delete()

            Log.d(TAG, "Legacy save success: ${targetFile.absolutePath}")
            result.success(targetFile.absolutePath)
        } catch (e: Exception) {
            Log.e(TAG, "saveToDownloadsLegacy exception: ${e.message}", e)
            result.error("SAVE_FAILED", "Failed to save via legacy: ${e.message}", null)
        }
    }

    // ── Utility ──────────────────────────────────────────────────────────────

    private fun resolveCollision(dir: File, fileName: String): File {
        val name = fileName.substringBeforeLast(".")
        val ext = fileName.substringAfterLast(".", "")
        var counter = 1
        var file = File(dir, fileName)
        while (file.exists()) {
            val newName = "$name ($counter).$ext"
            file = File(dir, newName)
            counter++
        }
        return file
    }
}
