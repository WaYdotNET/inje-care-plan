package com.injecare.injecare_plan

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Espone un MethodChannel ("injecare/saf") per il backup automatico locale via
 * Storage Access Framework: l'utente sceglie una cartella una volta, l'app
 * prende un permesso persistente e ci scrive/legge/cancella i backup.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "injecare/saf"
    private val openTreeRequest = 4711
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTree" -> openTree(result)
                    "isWritable" -> result.success(isWritable(call.argument("treeUri")))
                    "writeFile" -> writeFile(
                        call.argument("treeUri"),
                        call.argument("name"),
                        call.argument("bytes"),
                        result,
                    )
                    "listFiles" -> result.success(listFiles(call.argument("treeUri")))
                    "deleteFile" -> result.success(removeBackupDoc(call.argument("docUri")))
                    else -> result.notImplemented()
                }
            }
    }

    private fun openTree(result: MethodChannel.Result) {
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        startActivityForResult(intent, openTreeRequest)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != openTreeRequest) return
        val res = pendingResult
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            res?.success(null)
            return
        }
        val treeUri = data.data!!
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        try {
            contentResolver.takePersistableUriPermission(treeUri, flags)
        } catch (_: Exception) {
            // best-effort
        }
        val label = DocumentFile.fromTreeUri(this, treeUri)?.name
        res?.success(mapOf("treeUri" to treeUri.toString(), "label" to label))
    }

    private fun tree(treeUri: String?): DocumentFile? {
        if (treeUri == null) return null
        return DocumentFile.fromTreeUri(this, Uri.parse(treeUri))
    }

    private fun isWritable(treeUri: String?): Boolean {
        val dir = tree(treeUri) ?: return false
        return dir.exists() && dir.canWrite()
    }

    private fun writeFile(
        treeUri: String?,
        name: String?,
        bytes: ByteArray?,
        result: MethodChannel.Result,
    ) {
        try {
            val dir = tree(treeUri)
            if (dir == null || !dir.canWrite() || name == null || bytes == null) {
                result.error("unavailable", "Cartella non scrivibile", null)
                return
            }
            // Rimuove un eventuale file omonimo per evitare "name (1)".
            dir.findFile(name)?.delete()
            val file = dir.createFile("application/octet-stream", name)
            if (file == null) {
                result.error("create_failed", "Impossibile creare il file", null)
                return
            }
            contentResolver.openOutputStream(file.uri)?.use { it.write(bytes) }
            result.success(file.uri.toString())
        } catch (e: Exception) {
            result.error("write_failed", e.message, null)
        }
    }

    private fun listFiles(treeUri: String?): List<Map<String, Any?>> {
        val dir = tree(treeUri) ?: return emptyList()
        return dir.listFiles()
            .filter { it.isFile && (it.name?.startsWith("injecare-backup-") == true) }
            .map {
                mapOf(
                    "docUri" to it.uri.toString(),
                    "name" to it.name,
                    "lastModified" to it.lastModified(),
                )
            }
    }

    private fun removeBackupDoc(docUri: String?): Boolean {
        if (docUri == null) return false
        return try {
            DocumentFile.fromSingleUri(this, Uri.parse(docUri))?.delete() ?: false
        } catch (_: Exception) {
            false
        }
    }
}
