package com.qr.ajn

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "private_safe_qr/platform"
    private var channel: MethodChannel? = null
    private var sharedImagePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        processIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeSharedImage" -> {
                    val path = sharedImagePath
                    sharedImagePath = null
                    result.success(path)
                }
                "installedUpiApps" -> {
                    val probe = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay?pa=example@upi&pn=QR%20AJN"))
                    val apps = packageManager.queryIntentActivities(probe, 0)
                        .map { info ->
                            mapOf(
                                "package" to info.activityInfo.packageName,
                                "label" to info.loadLabel(packageManager).toString()
                            )
                        }
                        .distinctBy { it["package"] }
                        .sortedBy { it["label"] }
                    result.success(apps)
                }
                "openExternalUri" -> {
                    val uriText = call.argument<String>("uri") ?: ""
                    try {
                        val externalIntent = if (uriText.startsWith("intent://", ignoreCase = true)) {
                            Intent.parseUri(uriText, Intent.URI_INTENT_SCHEME)
                        } else {
                            Intent(Intent.ACTION_VIEW, Uri.parse(uriText))
                        }.apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addCategory(Intent.CATEGORY_BROWSABLE)
                        }
                        if (externalIntent.resolveActivity(packageManager) == null) {
                            result.success(false)
                        } else {
                            startActivity(externalIntent)
                            result.success(true)
                        }
                    } catch (error: Exception) {
                        result.error("EXTERNAL_OPEN_FAILED", error.message, null)
                    }
                }
                "openUpi" -> {
                    val uriText = call.argument<String>("uri") ?: ""
                    val packageName = call.argument<String>("package") ?: ""
                    try {
                        val paymentIntent = Intent(Intent.ACTION_VIEW, Uri.parse(uriText)).apply {
                            if (packageName.isNotBlank()) setPackage(packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        if (paymentIntent.resolveActivity(packageManager) == null) {
                            result.success(false)
                        } else {
                            startActivity(paymentIntent)
                            result.success(true)
                        }
                    } catch (error: Exception) {
                        result.error("UPI_OPEN_FAILED", error.message, null)
                    }
                }
                "saveBytesToDownloads" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "QR_AJN_export"
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    if (bytes == null) {
                        result.error("MISSING_BYTES", "No export data was provided", null)
                    } else {
                        try {
                            result.success(saveToDownloads(bytes, fileName, mimeType))
                        } catch (error: Exception) {
                            result.error("SAVE_FAILED", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("image/") == true) {
            @Suppress("DEPRECATION")
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            if (uri != null) {
                sharedImagePath = copyUriToCache(uri, "shared_${System.currentTimeMillis()}.img")
                channel?.invokeMethod("sharedImageAvailable", sharedImagePath)
            }
        }
    }

    private fun copyUriToCache(uri: Uri, name: String): String {
        val file = File(cacheDir, name)
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Unable to open shared file" }
            FileOutputStream(file).use { output -> input.copyTo(output) }
        }
        return file.absolutePath
    }

    private fun saveToDownloads(bytes: ByteArray, fileName: String, mimeType: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/QR AJN")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = requireNotNull(contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values))
            contentResolver.openOutputStream(uri).use { output ->
                requireNotNull(output) { "Unable to open Downloads output" }
                output.write(bytes)
            }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            uri.toString()
        } else {
            val directory = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
            val folder = File(directory, "QR AJN").apply { mkdirs() }
            val file = File(folder, fileName)
            FileOutputStream(file).use { it.write(bytes) }
            file.absolutePath
        }
    }
}
