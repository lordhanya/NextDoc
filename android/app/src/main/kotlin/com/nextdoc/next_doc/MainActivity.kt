package com.nextdoc.next_doc

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nextdoc.next_doc/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")
                val toolFolder = call.argument<String>("toolFolder")

                if (sourcePath == null || fileName == null || toolFolder == null) {
                    result.error("INVALID_ARGS", "Missing required arguments", null)
                    return@setMethodCallHandler
                }

                saveToDownloads(sourcePath, fileName, toolFolder, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        toolFolder: String,
        result: MethodChannel.Result,
    ) {
        try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) {
                result.error("FILE_NOT_FOUND", "Source file not found: $sourcePath", null)
                return
            }

            val mimeType = if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
                "image/jpeg"
            } else {
                "application/pdf"
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val relativePath = "NextDoc/$toolFolder/"

                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }

                val uri = contentResolver.insert(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    contentValues,
                )
                if (uri != null) {
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        sourceFile.inputStream().use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }

                    contentValues.clear()
                    contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                    contentResolver.update(uri, contentValues, null, null)

                    sourceFile.delete()

                    result.success(uri.toString())
                    return
                }
            }

            // Android < 10 or MediaStore fallback
            val downloadsDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val targetDir = File(downloadsDir, "NextDoc/$toolFolder")
            targetDir.mkdirs()

            val targetFile = resolveCollision(targetDir, fileName)
            sourceFile.copyTo(targetFile, overwrite = false)
            sourceFile.delete()

            result.success(targetFile.absolutePath)
        } catch (e: Exception) {
            result.error("SAVE_FAILED", "Failed to save: ${e.message}", null)
        }
    }

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
