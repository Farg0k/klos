package com.example.klos

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private var folderResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        requestNotificationPermissionIfNeeded()
                        val port = call.argument<Int>("port") ?: 8080
                        ServerService.start(
                            applicationContext,
                            port,
                            call.argument<String>("channelName"),
                            call.argument<String>("channelDescription"),
                            call.argument<String>("text"),
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        ServerService.stop(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendEmail" -> sendEmail(call, result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILES_CHANNEL)
            .setMethodCallHandler { call, result -> handleFileCall(call, result) }
    }

    /**
     * Storage Access Framework access to the folder the user chose.
     *
     * Only document URIs below the picked tree are accepted, so the HTTP
     * server cannot read arbitrary files even if it receives a crafted link.
     */
    private fun handleFileCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "checkAccess" -> {
                val uri = call.argument<String>("uri")
                if (uri.isNullOrBlank()) {
                    result.success(false)
                } else {
                    runAsync(result) { checkAccess(Uri.parse(uri)) }
                }
            }
            "listFolder" -> {
                val uri = call.argument<String>("uri")
                if (uri.isNullOrBlank()) {
                    result.error("invalid_uri", "URI is missing", null)
                } else {
                    runAsync(result) { listFolder(Uri.parse(uri)) }
                }
            }
            "readFile" -> {
                val uri = call.argument<String>("uri")
                val maxBytes = (call.argument<Any>("maxBytes") as? Number)?.toLong()
                    ?: Long.MAX_VALUE
                if (uri.isNullOrBlank()) {
                    result.error("invalid_uri", "URI is missing", null)
                } else {
                    runAsync(result) { readFile(Uri.parse(uri), maxBytes) }
                }
            }
            "writeFile" -> {
                val uri = call.argument<String>("uri")
                val name = call.argument<String>("name")
                val mime = call.argument<String>("mime")
                    ?: "application/octet-stream"
                val bytes = call.argument<ByteArray>("bytes")
                if (uri.isNullOrBlank() || name.isNullOrBlank() || bytes == null) {
                    result.error("invalid_args", "Folder, name or data is missing", null)
                } else {
                    runAsync(result) {
                        writeFile(Uri.parse(uri), name, mime, bytes)
                    }
                }
            }
            "folderName" -> {
                val uri = call.argument<String>("uri")
                if (uri.isNullOrBlank()) {
                    result.success(null)
                } else {
                    runAsync(result) { folderName(Uri.parse(uri)) }
                }
            }
            "parent" -> {
                val tree = call.argument<String>("treeUri")
                val uri = call.argument<String>("uri")
                if (tree.isNullOrBlank() || uri.isNullOrBlank()) {
                    result.success(null)
                } else {
                    runAsync(result) { parentOf(Uri.parse(tree), Uri.parse(uri)) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (folderResult != null) {
            result.error("already_running", "Another folder picker is open", null)
            return
        }
        folderResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
            )
        }
        // Downloads is the default folder, so the picker opens there.
        initialDownloadsUri()?.let {
            intent.putExtra("android.provider.extra.INITIAL_URI", it)
        }
        try {
            startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (error: Exception) {
            folderResult = null
            result.error(
                "picker_failed",
                error.message ?: "The folder picker is unavailable",
                null,
            )
        }
    }

    private fun initialDownloadsUri(): Uri? {
        return try {
            DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents",
                "primary:Download",
            )
        } catch (error: Exception) {
            null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_FOLDER) return

        val result = folderResult ?: return
        folderResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (error: Exception) {
            // A provider may grant only read access. Keep what it allows, so
            // the Kindle still sees the folder and the app can ask for write
            // permission again when a download needs it.
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (readError: Exception) {
                // Some providers grant access without persistable permission.
            }
        }
        result.success(
            hashMapOf(
                "uri" to uri.toString(),
                "name" to (folderName(uri) ?: ""),
            ),
        )
    }

    private fun checkAccess(uri: Uri): Boolean {
        var granted = false
        for (permission in contentResolver.persistedUriPermissions) {
            if (!permission.isReadPermission) continue
            val allowed = permission.uri.toString()
            if (allowed == uri.toString() || uri.toString().startsWith(allowed)) {
                granted = true
                break
            }
        }
        if (!granted) return false
        return try {
            childDocumentsUri(uri)?.let { children ->
                contentResolver.query(
                    children,
                    arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                    null,
                    null,
                    null,
                )?.use { it.moveToFirst() }
            } != null
        } catch (error: Exception) {
            false
        }
    }

    private fun listFolder(folderUri: Uri): List<Map<String, Any?>> {
        val files = mutableListOf<Map<String, Any?>>()
        val children = childDocumentsUri(folderUri) ?: return files
        try {
            contentResolver.query(
                children,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                    DocumentsContract.Document.COLUMN_SIZE,
                ),
                null,
                null,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(0) ?: continue
                    val documentId = cursor.getString(1) ?: continue
                    val mime = cursor.getString(2) ?: ""
                    files.add(
                        hashMapOf(
                            "name" to name,
                            "uri" to DocumentsContract.buildDocumentUriUsingTree(
                                folderUri,
                                documentId,
                            ).toString(),
                            "mimeType" to mime,
                            "size" to (if (cursor.isNull(3)) 0L else cursor.getLong(3)),
                            "isDirectory" to (mime == DocumentsContract.Document.MIME_TYPE_DIR),
                        ),
                    )
                }
            }
        } catch (error: SecurityException) {
            throw error
        }
        return files
    }

    private fun readFile(uri: Uri, maxBytes: Long): ByteArray {
        declaredSize(uri)?.let {
            if (it > maxBytes) throw FileTooLargeException()
        }
        val input: InputStream = contentResolver.openInputStream(uri)
            ?: throw IllegalArgumentException("The document cannot be opened")
        input.use { stream ->
            val output = ByteArrayOutputStream()
            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
            var total = 0L
            while (true) {
                val read = stream.read(buffer)
                if (read < 0) break
                total += read
                if (total > maxBytes) throw FileTooLargeException()
                output.write(buffer, 0, read)
            }
            return output.toByteArray()
        }
    }

    /**
     * Saves a downloaded book into the folder the Kindle can read.
     *
     * The provider chooses the final name when a file with the same name is
     * already there, so the real display name is returned. A partially written
     * file is removed, leaving the folder as it was.
     */
    private fun writeFile(
        folderUri: Uri,
        name: String,
        mime: String,
        bytes: ByteArray,
    ): Map<String, Any?> {
        val parent = folderDocumentUri(folderUri)
            ?: throw IllegalArgumentException("The folder cannot be opened")
        val documentUri = try {
            DocumentsContract.createDocument(contentResolver, parent, mime, name)
        } catch (error: SecurityException) {
            throw WriteDeniedException()
        } ?: throw IllegalArgumentException("The file cannot be created")

        try {
            val output = contentResolver.openOutputStream(documentUri, "w")
                ?: throw IllegalArgumentException("The file cannot be opened for writing")
            output.use { it.write(bytes) }
        } catch (error: SecurityException) {
            deleteQuietly(documentUri)
            throw WriteDeniedException()
        } catch (error: Exception) {
            deleteQuietly(documentUri)
            throw error
        }

        return hashMapOf(
            "uri" to documentUri.toString(),
            "name" to (displayName(documentUri) ?: name),
        )
    }

    private fun folderDocumentUri(uri: Uri): Uri? {
        return try {
            if (DocumentsContract.isTreeUri(uri)) {
                DocumentsContract.buildDocumentUriUsingTree(
                    uri,
                    DocumentsContract.getTreeDocumentId(uri),
                )
            } else {
                uri
            }
        } catch (error: Exception) {
            null
        }
    }

    private fun deleteQuietly(uri: Uri) {
        try {
            DocumentsContract.deleteDocument(contentResolver, uri)
        } catch (error: Exception) {
            // The write error is more useful than a failed cleanup.
        }
    }

    private fun parentOf(treeUri: Uri, uri: Uri): Map<String, Any?>? {
        val treeId = try {
            DocumentsContract.getTreeDocumentId(treeUri)
        } catch (error: Exception) {
            return null
        }
        val documentId = documentIdOf(uri) ?: return null
        if (documentId == treeId) return null

        val parentId = when {
            documentId.contains('/') -> documentId.substringBeforeLast('/')
            else -> treeId
        }
        if (parentId != treeId && !parentId.startsWith("$treeId/")) return null

        val name = try {
            displayName(
                DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId),
            ) ?: ""
        } catch (error: Exception) {
            ""
        }
        val parentUri = try {
            DocumentsContract.buildDocumentUriUsingTree(treeUri, parentId)
        } catch (error: Exception) {
            return null
        }
        return hashMapOf("uri" to parentUri.toString(), "name" to name)
    }

    private fun childDocumentsUri(folderUri: Uri): Uri? {
        val documentId = documentIdOf(folderUri) ?: return null
        return try {
            DocumentsContract.buildChildDocumentsUriUsingTree(folderUri, documentId)
        } catch (error: Exception) {
            null
        }
    }

    private fun documentIdOf(uri: Uri): String? {
        return try {
            if (DocumentsContract.isDocumentUri(this, uri)) {
                DocumentsContract.getDocumentId(uri)
            } else {
                DocumentsContract.getTreeDocumentId(uri)
            }
        } catch (error: Exception) {
            // A child document URI keeps the tree in its path; split it manually.
            val segments = uri.pathSegments
            if (segments.size >= 2 && segments[0] == "tree") segments[1] else null
        }
    }

    private fun displayName(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor: Cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (error: Exception) {
            null
        }
    }

    /**
     * Name of the folder behind a tree URI.
     *
     * Querying the tree URI itself returns the title of its root ("Downloads")
     * or nothing at all, which is why the UI kept showing "Downloads" after a
     * subfolder was picked. The document the tree points at is queried instead.
     * External storage document ids look like "primary:Download/Books", so the
     * last part is used when a provider does not answer.
     */
    private fun folderName(treeUri: Uri): String? {
        val documentId = try {
            DocumentsContract.getTreeDocumentId(treeUri)
        } catch (error: Exception) {
            null
        } ?: return null
        val documentUri = try {
            DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
        } catch (error: Exception) {
            null
        }
        val queried = documentUri?.let { displayName(it) }?.trim()
        if (!queried.isNullOrEmpty()) return queried
        if (!documentId.contains(':')) return null
        return documentId
            .substringAfter(':')
            .substringAfterLast('/')
            .trim()
            .takeIf { it.isNotEmpty() }
    }

    private fun declaredSize(uri: Uri): Long? {
        return try {
            contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_SIZE),
                null,
                null,
                null,
            )?.use { cursor: Cursor ->
                if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getLong(0) else null
            }
        } catch (error: Exception) {
            null
        }
    }

    private fun <T> runAsync(result: MethodChannel.Result, block: () -> T) {
        Thread {
            try {
                val value = block()
                runOnUiThread { result.success(value) }
            } catch (error: FileTooLargeException) {
                runOnUiThread { result.error("file_too_large", "The file is too large", null) }
            } catch (error: WriteDeniedException) {
                runOnUiThread {
                    result.error("write_denied", "Write access is missing", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "io_error",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }
        }.start()
    }

    private class FileTooLargeException : Exception()

    private class WriteDeniedException : Exception()

    /**
     * Opens a mail composer with the book attached and the Kindle address
     * prefilled. Android's ACTION_SEND supports EXTRA_EMAIL, which share_plus
     * does not expose.
     */
    private fun sendEmail(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val mime = call.argument<String>("mime") ?: "*/*"
        val to = call.argument<String>("to")?.trim()
        val subject = call.argument<String>("subject") ?: ""
        val text = call.argument<String>("text") ?: ""
        val chooserTitle = call.argument<String>("chooser") ?: "Надіслати книгу на Kindle"

        if (path.isNullOrBlank() || to.isNullOrBlank()) {
            result.error("bad_args", "Не вказано файл або адресу Kindle.", null)
            return
        }

        val file = File(path)
        if (!file.exists()) {
            result.error("missing_file", "Файл книги не знайдено.", null)
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.klos.mail_provider",
                file,
            )
            val send = Intent(Intent.ACTION_SEND).apply {
                type = mime
                putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(send, chooserTitle)
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(chooser)
            result.success(null)
        } catch (error: Exception) {
            result.error(
                "send_failed",
                error.message ?: "Не вдалося відкрити поштову програму.",
                null,
            )
        }
    }

    override fun onDestroy() {
        // The Dart HTTP server lives in this activity's Flutter engine.
        // If the activity goes away, the foreground service must not linger
        // as a notification without a working server.
        ServerService.stop(applicationContext)
        super.onDestroy()
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    companion object {
        private const val CHANNEL = "klos/foreground"
        private const val SHARE_CHANNEL = "klos/share"
        private const val FILES_CHANNEL = "klos/files"
        private const val REQUEST_NOTIFICATIONS = 1001
        private const val REQUEST_PICK_FOLDER = 1002
    }
}