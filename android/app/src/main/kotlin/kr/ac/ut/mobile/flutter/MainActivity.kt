package kr.ac.ut.mobile.flutter

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.os.RemoteException
import android.provider.Settings
import android.webkit.ValueCallback
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.altbeacon.beacon.Beacon
import org.altbeacon.beacon.BeaconConsumer
import org.altbeacon.beacon.BeaconManager
import org.altbeacon.beacon.BeaconParser
import org.altbeacon.beacon.Region
import java.util.Locale
import kotlin.system.exitProcess

/**
 * 원본 IntroActivity·MainActivity 가운데 Android가 직접 처리하던 부분.
 * 화면과 흐름은 Dart(lib/)에 있고, 여기서는 채널로 요청받은 일을 원본 코드와 같은 API로 처리한다.
 */
class MainActivity : FlutterActivity(), BeaconConsumer {
    companion object {
        const val CHANNEL = "kr.ac.ut.mobile.flutter/native"
        const val REQUEST_PERMISSIONS = 1
        const val REQUEST_STORAGE_PERMISSION = 1004
        const val REQUEST_FILE_CHOOSER = 1

        /** 개선판이 따로 기억하는 값(루팅 안내를 보였는지). */
        private const val PREFS = "renewal"
        private const val KEY_ROOTING_NOTICE_SHOWN = "rooting_notice_shown"

        /** foreground dispatch로 들어온 NFC 인텐트 표시. */
        private const val EXTRA_FOREGROUND_DISPATCH = "kr.ac.ut.mobile.flutter.FOREGROUND_DISPATCH"
    }

    var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
        private set
    private var channel: MethodChannel? = null
    private val webViews = WebViewBridge(this)

    private var launchPushUrl: String? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDownload: (() -> Unit)? = null
    var fileChooserCallback: ValueCallback<Array<Uri>>? = null

    private var nfcAdapter: NfcAdapter? = null
    private var nfcPendingIntent: PendingIntent? = null
    private var mainActive = false
    private var resumed = false

    private var beaconManager: BeaconManager? = null
    private val beacons = ArrayList<Beacon>()
    private var beaconRegion: Region? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchPushUrl = intent?.getStringExtra("push_url")?.takeIf { !it.equals("", ignoreCase = true) }
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        nfcPendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, javaClass)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(EXTRA_FOREGROUND_DISPATCH, true),
            PendingIntent.FLAG_MUTABLE,
        )
        val manager = BeaconManager.getInstanceForApplication(this)
        manager.beaconParsers.add(BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"))
        beaconManager = manager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(object : FlutterPlugin {
            override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
                pluginBinding = binding
            }

            override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
                pluginBinding = null
            }
        })
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(::onMethodCall)
        }
    }

    fun invokeDart(method: String, arguments: Any?) {
        channel?.invokeMethod(method, arguments)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "deviceInfo" -> result.success(
                mapOf(
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "model" to Build.MODEL,
                    "release" to Build.VERSION.RELEASE,
                    "language" to Locale.getDefault().language,
                    "versionName" to versionName(),
                ),
            )
            "takeLaunchPushUrl" -> {
                result.success(launchPushUrl)
                launchPushUrl = null
            }
            "isNetworkConnected" -> result.success(isNetworkConnected())
            "checkPermissions" -> result.success(allGranted(call.arguments<List<String>>()!!))
            "requestPermissions" -> {
                if (pendingPermissionResult != null) {
                    // 이미 다른 기능이 권한을 묻는 중이다: 이 요청은 중단된 것으로 돌려준다.
                    result.success(emptyList<Any>())
                    return
                }
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    call.arguments<List<String>>()!!.toTypedArray(),
                    REQUEST_PERMISSIONS,
                )
            }
            "shouldShowRationale" -> result.success(
                ActivityCompat.shouldShowRequestPermissionRationale(this, call.arguments<String>()!!),
            )
            "showPermissionSettings" -> {
                showPermissionSettings(call.arguments<String>()!!)
                result.success(null)
            }
            "toast" -> {
                val text = call.argument<String>("text")
                val long = call.argument<Boolean>("long") == true
                Toast.makeText(this, text, if (long) Toast.LENGTH_LONG else Toast.LENGTH_SHORT).show()
                result.success(null)
            }
            "finishAffinity" -> {
                finishAffinity()
                result.success(null)
            }
            "exitProcess" -> {
                result.success(null)
                exitApp()
            }
            "startView" -> {
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments<String>())))
                } catch (_: Exception) {
                }
                result.success(null)
            }
            "launchPackage" -> result.success(launchPackage(call.arguments<String>()!!))
            "checkRooting" -> {
                checkRooting()
                result.success(null)
            }
            "installWebView" -> {
                webViews.install(call.argument<Number>("id")!!.toLong(), call.argument<String>("kind")!!)
                result.success(null)
            }
            "attachWindow" -> {
                webViews.attachWindow(call.argument<Int>("token")!!, call.argument<Number>("id")!!.toLong())
                result.success(null)
            }
            "destroyWebView" -> {
                webViews.destroy(call.arguments<Number>()!!.toLong())
                result.success(null)
            }
            "loadUrl" -> {
                webViews.loadUrl(
                    call.argument<Number>("id")!!.toLong(),
                    call.argument<String>("url")!!,
                    call.argument<Map<String, String>>("headers")!!,
                )
                result.success(null)
            }
            "loadJavascriptUrl" -> {
                webViews.loadJavascriptUrl(call.argument<Number>("id")!!.toLong(), call.argument<String>("script")!!)
                result.success(null)
            }
            "nfcState" -> {
                val adapter = (getSystemService(Context.NFC_SERVICE) as NfcManager?)?.defaultAdapter
                result.success(
                    when {
                        adapter == null -> "none"
                        adapter.isEnabled -> "enabled"
                        else -> "disabled"
                    },
                )
            }
            "setMainActive" -> {
                mainActive = call.arguments<Boolean>() == true
                updateForegroundDispatch()
                result.success(null)
            }
            "gpsUrl" -> result.success(gpsUrl(call.arguments<String>()!!))
            "beaconStart" -> {
                beaconManager?.bind(this)
                result.success(null)
            }
            "beaconStop" -> result.success(beaconStop())
            else -> result.notImplemented()
        }
    }

    private fun versionName(): String = try {
        packageManager.getPackageInfo(packageName, 0).versionName ?: ""
    } catch (_: PackageManager.NameNotFoundException) {
        ""
    }

    /** BaseActivity `U()`: 와이파이(1) 또는 모바일(0)로 연결되어 있는지. */
    @Suppress("DEPRECATION")
    private fun isNetworkConnected(): Boolean {
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager? ?: return false
        val info = manager.activeNetworkInfo ?: return false
        return info.isConnected &&
            (info.type == ConnectivityManager.TYPE_WIFI || info.type == ConnectivityManager.TYPE_MOBILE)
    }

    private fun allGranted(permissions: List<String>): Boolean =
        permissions.all { ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_PERMISSIONS -> {
                val result = pendingPermissionResult ?: return
                pendingPermissionResult = null
                result.success(
                    permissions.indices.filter { it < grantResults.size }.map {
                        mapOf("permission" to permissions[it], "result" to grantResults[it])
                    },
                )
            }
            REQUEST_STORAGE_PERMISSION -> {
                val download = pendingDownload
                pendingDownload = null
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    download?.invoke()
                } else {
                    Toast.makeText(this, "저장공간 권한이 없어 파일을 내려받지 못했습니다.", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    /**
     * 원본 IntroActivity `o0()`는 거부한 권한을 `[카메라]권한을 추가해 주세요.`로 알리고 설정 화면을
     * 연 뒤 앱을 끝냈다. 개선판은 기능을 쓸 때만 안내하고, 설정으로 갈지는 사용자가 고른다(통합본 1-1).
     */
    private fun showPermissionSettings(message: String) {
        AlertDialog.Builder(this)
            .setMessage(message)
            .setPositiveButton("설정 열기") { _, _ ->
                val intent = Intent()
                intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                intent.addCategory(Intent.CATEGORY_DEFAULT)
                intent.data = Uri.parse("package:$packageName")
                runCatching { startActivity(intent) }
            }
            .setNegativeButton("닫기", null)
            .create()
            .show()
    }

    /**
     * 내려받기(Android 9 이하만): 공용 Download 폴더에 쓰려면 저장공간 권한이 필요하다. 원본은
     * 첫 실행에 받아 두었고, 개선판은 내려받을 때 요청한 뒤 허용하면 이어서 내려받는다.
     */
    fun requestStoragePermission(download: () -> Unit) {
        pendingDownload = download
        Toast.makeText(this, "파일을 저장하려면 저장공간 권한이 필요합니다.", Toast.LENGTH_LONG).show()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
            REQUEST_STORAGE_PERMISSION,
        )
    }

    /** MainActivity `d0()`. */
    private fun exitApp() {
        finish()
        exitProcess(0)
        @Suppress("UNREACHABLE_CODE")
        Process.killProcess(Process.myPid())
    }

    /** MainActivity `a1()`. */
    private fun launchPackage(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    /**
     * MainActivity `onCreate` 끝의 루팅 확인과 `j1()`.
     *
     * 원본은 `su`를 실행해 보고 성공하면 `루팅된 기기는 사용할 수 없습니다.`를 띄운 뒤 앱을 끝냈다.
     * 개선판은 앱을 막지 않고 처음 한 번만 안내한다(통합본 1-2). `su`를 실행하면 루팅 관리 앱이 권한
     * 요청 창을 띄울 수 있어서, 실행하지 않고 이 앱이 실행할 수 있는 `su` 파일이 있는지만 본다.
     * (에뮬레이터의 Google APIs 이미지에는 셸만 실행할 수 있는 `su`가 있다. 원본도 이때는 실행에
     * 실패해 루팅으로 보지 않았다.)
     */
    private fun checkRooting() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(KEY_ROOTING_NOTICE_SHOWN, false) || !hasSuBinary()) return
        prefs.edit().putBoolean(KEY_ROOTING_NOTICE_SHOWN, true).apply()
        AlertDialog.Builder(this)
            .setMessage(
                "루팅된 기기로 보입니다.\n" +
                    "루팅된 기기에서는 개인정보가 다른 앱에 노출될 수 있으니 주의해서 사용해 주세요.",
            )
            .setPositiveButton("확인", null)
            .create()
            .show()
    }

    private fun hasSuBinary(): Boolean {
        val dirs = (System.getenv("PATH") ?: "").split(':') +
            listOf("/system/bin", "/system/xbin", "/sbin", "/su/bin", "/data/local/bin", "/data/local/xbin")
        return dirs.filter { it.isNotEmpty() }.distinct().any {
            val su = java.io.File(it, "su")
            su.exists() && su.canExecute()
        }
    }

    /**
     * MainActivity `W0()`. 위치 권한이 없으면 0으로 보낸다.
     * 위도 자리에 경도가 들어가는 것, 방위각이 늘 0인 것까지 원본 그대로다(HANDOFF 5.14).
     *
     * 원본은 정밀 위치 권한만 보고, 없으면 여기서 요청만 한 채 0을 보냈다. 개선판은 Dart가 먼저
     * 위치 권한을 요청하고(통합본 1-1), 대략 위치만 허용했으면 network 위치를 쓴다.
     */
    private fun gpsUrl(url: String): String? {
        return try {
            val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val fine = ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            val coarse = ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            var longitude = 0.0
            var latitude = 0.0
            var altitude = 0.0
            if (fine || coarse) {
                val network = runCatching { manager.getLastKnownLocation("network") }.getOrNull()
                if (network != null) {
                    longitude = network.longitude
                    latitude = network.latitude
                    altitude = network.altitude
                }
            }
            if (fine) {
                val gps = runCatching { manager.getLastKnownLocation("gps") }.getOrNull()
                if (gps != null) {
                    longitude = gps.longitude
                    latitude = gps.latitude
                    altitude = gps.altitude
                }
            }
            String.format(url + "&latitude=%s&longitude=%s&altitude=%s&azimuth=%s", longitude, latitude, altitude, 0.0f)
        } catch (_: Exception) {
            null
        }
    }

    // ---- 비콘(원본 j2 = AltBeacon) ----

    override fun onBeaconServiceConnect() {
        val manager = beaconManager ?: return
        val region = Region("nearMeScanning", null, null, null)
        beaconRegion = region
        manager.addRangeNotifier { found, _ ->
            if (found.isNotEmpty()) beacons.addAll(found)
        }
        try {
            @Suppress("DEPRECATION")
            manager.startRangingBeaconsInRegion(region)
        } catch (_: RemoteException) {
        }
    }

    /** MainActivity `z0()`의 네이티브 부분: 찾은 비콘을 넘기고 검색을 멈춘다. */
    private fun beaconStop(): List<List<String>> {
        val found = beacons.map { listOf(it.id1.toString(), it.id2.toString(), it.id3.toString()) }
        val manager = beaconManager
        if (manager != null) {
            try {
                beaconRegion?.let {
                    @Suppress("DEPRECATION")
                    manager.stopRangingBeaconsInRegion(it)
                }
            } catch (_: RemoteException) {
            }
            manager.unbind(this)
        }
        beacons.clear()
        return found
    }

    // ---- NFC ----

    private fun updateForegroundDispatch() {
        val adapter = nfcAdapter ?: return
        if (resumed && mainActive) {
            adapter.enableForegroundDispatch(this, nfcPendingIntent, null, null)
        } else if (resumed) {
            adapter.disableForegroundDispatch(this)
        }
    }

    override fun onResume() {
        super.onResume()
        resumed = true
        updateForegroundDispatch()
    }

    override fun onPause() {
        super.onPause()
        if (mainActive) nfcAdapter?.disableForegroundDispatch(this)
        resumed = false
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_FOREGROUND_DISPATCH, false)) {
            readNfcTag(intent)
            return
        }
        // 원본에서는 IntroActivity가 새로 떠서 기기 등록을 다시 한 뒤 MainActivity로 넘긴다.
        val pushUrl = intent.getStringExtra("push_url")?.takeIf { !it.equals("", ignoreCase = true) }
        if (pushUrl != null || intent.action == NfcAdapter.ACTION_NDEF_DISCOVERED) {
            invokeDart("relaunchIntro", pushUrl)
        }
    }

    /**
     * MainActivity `onNewIntent`의 NFC 처리: 첫 NDEF 메시지의 세 번째 레코드를 읽어 첫 `s`부터 자른다.
     * 레코드가 3개보다 적으면 원본은 예외로 종료되지만, 사용자 결정에 따라 조용히 무시한다.
     */
    private fun readNfcTag(intent: Intent) {
        @Suppress("DEPRECATION")
        intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG) ?: return
        @Suppress("DEPRECATION")
        val messages = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
        var value: String? = null
        if (messages != null && messages.isNotEmpty()) {
            val records = (messages[0] as NdefMessage).records
            if (records.size < 3) return
            val text = String(records[2].payload, Charsets.UTF_8)
            val index = text.indexOf('s')
            value = if (index != -1) text.substring(index).trim { it <= ' ' } else text
        }
        if (value.isNullOrEmpty()) return
        invokeDart("nfcTag", value)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_FILE_CHOOSER || resultCode != RESULT_OK || data == null) return
        val callback = fileChooserCallback ?: return
        val clip = data.clipData
        if (clip == null) {
            data.data?.let { callback.onReceiveValue(arrayOf(it)) }
        } else {
            callback.onReceiveValue(Array(clip.itemCount) { clip.getItemAt(it).uri })
        }
    }

    /** 휴대폰 글자 크기 설정을 바꾸면 웹 글자 크기도 따라간다(통합본 5-1). 매니페스트 configChanges에 fontScale이 있다. */
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        webViews.applyTextZoom()
    }

    override fun onDestroy() {
        super.onDestroy()
        beaconManager?.unbind(this)
    }
}
