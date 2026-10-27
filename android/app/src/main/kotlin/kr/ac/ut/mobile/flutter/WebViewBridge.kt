package kr.ac.ut.mobile.flutter

import android.Manifest
import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.net.http.SslError
import android.os.Build
import android.os.Environment
import android.os.Message
import android.view.KeyEvent
import android.view.View
import android.webkit.ClientCertRequest
import android.webkit.ConsoleMessage
import android.webkit.CookieManager
import android.webkit.DownloadListener
import android.webkit.GeolocationPermissions
import android.webkit.HttpAuthHandler
import android.webkit.JavascriptInterface
import android.webkit.JsPromptResult
import android.webkit.JsResult
import android.webkit.PermissionRequest
import android.webkit.SslErrorHandler
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat
import io.flutter.plugins.webviewflutter.WebChromeClientProxyApi
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi
import java.net.URISyntaxException
import java.net.URLDecoder

/**
 * webview_flutter가 만든 네이티브 WebView에 원본 MainActivity의 WebView 설정을 그대로 입힌다.
 *
 * - kind `main`: 원본 `X0()` + 클라이언트 `i`
 * - kind `popup`: 원본 `Z0()` + 클라이언트 `l`(크롬), `n`(링크), 다운로드 `j`
 * - kind `child`: `window.open`으로 열린 창(크롬 `f`, 클라이언트 `g`)
 * - kind `grandchild`: 그 창에서 다시 열린 창(크롬 `C0091f`)
 *
 * 페이지 시작·끝 이벤트는 플러그인 클라이언트를 거쳐 Dart로 그대로 전달된다. 개선판은 로딩 표시와
 * 연결 안내(통합본 3-31, 1-9, 6-10)를 위해 플러그인이 넘기지 않는 이벤트를 `webEvent`로 더 보낸다.
 */
class WebViewBridge(private val activity: MainActivity) {
    private val pendingWindows = HashMap<Int, Message>()
    private var nextToken = 1

    /** 설정을 입힌 웹뷰들. 휴대폰 글자 크기를 바꾸면 모두 다시 맞춘다. */
    private val installed = LinkedHashSet<Long>()

    private fun webView(id: Long): WebView? {
        val binding = activity.pluginBinding ?: return null
        return WebViewFlutterAndroidExternalApi.getWebView(binding, id)
    }

    @SuppressLint("SetJavaScriptEnabled", "JavascriptInterface")
    fun install(id: Long, kind: String, textZoom: Int) {
        val webView = webView(id) ?: return
        val s = webView.settings
        // 원본은 출시 버전에서도 켜 두었다. 개선판은 debug 빌드에서만 켠다(통합본 9-1).
        WebView.setWebContentsDebuggingEnabled(
            (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0,
        )
        // webview_flutter가 생성자에서 바꿔 둔 값을 Android 기본값으로 되돌린 뒤 원본 설정을 입힌다.
        s.loadWithOverviewMode = false
        s.useWideViewPort = false
        // 원본은 확대를 막았다(builtInZoomControls 기본값 false). 개선판은 두 손가락 확대를 허용하고
        // 확대 버튼은 숨긴다(통합본 5-2). 페이지가 확대를 막아도 풀어 주는 스크립트는 ShellWebViewClient.
        s.setSupportZoom(true)
        s.builtInZoomControls = true
        s.displayZoomControls = false
        s.javaScriptEnabled = true
        s.domStorageEnabled = true
        // 원본은 85% 고정이었다. 개선판은 휴대폰 글자 크기 설정을 상한까지 따른다(통합본 5-1).
        // 값은 Dart가 정해 보낸다(`web_entry.dart` `textZoomFor`).
        s.textZoom = textZoom
        installed.add(id)
        when (kind) {
            "main" -> {
                s.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                @Suppress("DEPRECATION")
                s.databaseEnabled = true
                s.javaScriptCanOpenWindowsAutomatically = false
                s.setSupportMultipleWindows(false)
                webView.scrollBarStyle = View.SCROLLBARS_OUTSIDE_OVERLAY
                webView.isScrollbarFadingEnabled = true
                webView.addJavascriptInterface(AllytteJs(), "allytteAndroid")
                // 원본 메인 웹뷰는 내려받지 않는다. 이동이 내려받기로 끝났다는 것만 알린다.
                webView.setDownloadListener { url, _, _, _, _ -> event(id, "download", url) }
            }
            "popup" -> {
                s.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                @Suppress("DEPRECATION")
                s.databaseEnabled = true
                s.javaScriptCanOpenWindowsAutomatically = true
                s.setSupportMultipleWindows(true)
                webView.addJavascriptInterface(AllytteJs(), "allytteAndroid")
                webView.setDownloadListener(downloadListener(id))
            }
            else -> {
                s.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
                s.javaScriptCanOpenWindowsAutomatically = true
                s.setSupportMultipleWindows(true)
                s.allowFileAccess = true
                s.allowContentAccess = true
                @Suppress("DEPRECATION")
                s.allowFileAccessFromFileURLs = true
                @Suppress("DEPRECATION")
                s.allowUniversalAccessFromFileURLs = true
                webView.setDownloadListener(downloadListener(id))
            }
        }
        // 클라이언트를 감싸려면 현재 클라이언트를 읽어야 해서 Android 8.0 이상에서만 가능하다.
        // 원본은 메인 웹뷰의 크롬 클라이언트를 두 번 설정해서 JS 알림창이 시스템 기본 창(제목
        // `'https://mobile.ut.ac.kr' 페이지 내용:`)으로 떴다. 개선판은 메인도 팝업과 같은 창을 쓴다.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            webView.webViewClient = ShellWebViewClient(id, kind, webView.webViewClient)
            val chrome = webView.webChromeClient
            if (chrome != null) {
                webView.webChromeClient = ShellChromeClient(id, kind, chrome)
            }
        }
    }

    /** `onCreateWindow`에서 기다리게 해 둔 창에 Dart가 만든 WebView를 넘긴다. */
    fun attachWindow(token: Int, id: Long) {
        val message = pendingWindows.remove(token) ?: return
        val webView = webView(id) ?: return
        (message.obj as WebView.WebViewTransport).webView = webView
        message.sendToTarget()
    }

    fun clearHistory(id: Long) {
        webView(id)?.clearHistory()
    }

    fun destroy(id: Long) {
        webView(id)?.destroy()
        installed.remove(id)
    }

    /** 앱이 떠 있는 동안 글자 크기 설정을 바꾸면 열려 있는 웹뷰에도 바로 반영한다. */
    fun setTextZoom(zoom: Int) {
        installed.toList().forEach { id ->
            val webView = webView(id)
            if (webView == null) installed.remove(id) else webView.settings.textZoom = zoom
        }
    }

    /** Dart [WebEntry]에 보내는 웹뷰 이벤트: navigate, committed, visible, download. */
    private fun event(id: Long, type: String, url: String?, extra: Map<String, Any> = emptyMap()) {
        activity.invokeDart("webEvent", mapOf("id" to id, "type" to type, "url" to url) + extra)
    }

    /** 원본 `B0()`/`c1()`의 `loadUrl(url, extraHeaders)`. */
    fun loadUrl(id: Long, url: String, headers: Map<String, String>) {
        webView(id)?.loadUrl(url, HashMap(headers))
    }

    /** 원본처럼 `loadUrl("javascript:...")`로 실행한다. */
    fun loadJavascriptUrl(id: Long, script: String) {
        webView(id)?.loadUrl("javascript:$script")
    }

    /** 원본 클래스 `h`/`m`: 웹 페이지가 부르는 `allytteAndroid` 객체. */
    inner class AllytteJs {
        @JavascriptInterface
        fun addressSave(phone: String) {
            val intent = Intent(Intent.ACTION_INSERT)
            intent.type = "vnd.android.cursor.dir/raw_contact"
            intent.putExtra("phone", phone).putExtra("phone_type", 3)
            runCatching { activity.startActivity(intent) }
        }

        @JavascriptInterface
        fun allytteCommandHandler(json: String?) {
            activity.runOnUiThread { activity.invokeDart("jsCommand", json) }
        }
    }

    private fun startQuietly(intent: Intent) {
        // 원본은 처리할 앱이 없으면 예외로 종료된다. 강제 종료는 재현하지 않는다.
        try {
            activity.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    /** 원본 클라이언트 `i`(메인)와 `n`(팝업)의 `shouldOverrideUrlLoading`. */
    private fun overrideUrl(kind: String, url: String): Boolean {
        if (kind == "popup") {
            if (url.startsWith("intent://")) {
                try {
                    val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
                    try {
                        activity.startActivity(intent)
                    } catch (_: ActivityNotFoundException) {
                        val pkg = intent.getPackage()
                        if (pkg != null && pkg != "") {
                            startQuietly(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg")))
                        }
                    }
                } catch (_: URISyntaxException) {
                }
                return true
            }
            if (url.startsWith("https://play.google.com/store/apps/details?id=") ||
                url.startsWith("market://details?id=")
            ) {
                val id = Uri.parse(url).getQueryParameter("id")
                if (id != null && id != "") {
                    startQuietly(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$id")))
                }
                return true
            }
        }
        if (kind == "main" || kind == "popup") {
            if (url.startsWith("sms:")) {
                startQuietly(Intent(Intent.ACTION_SENDTO, Uri.parse(url)))
                return true
            }
            if (url.startsWith("tel:")) {
                startQuietly(Intent(Intent.ACTION_DIAL, Uri.parse(url)))
                return true
            }
            if (url.startsWith("mailto:")) {
                startQuietly(Intent(Intent.ACTION_SENDTO, Uri.parse(url)))
                return true
            }
        }
        return false
    }

    /**
     * 원본 `j`/`e` 다운로드 처리.
     *
     * 원본은 실패하면 그때 저장공간 권한을 요청하고 다시 눌러야 했다. 개선판은 권한이 필요한
     * Android 9 이하에서만, 권한이 없을 때 먼저 요청하고 허용하면 이어서 내려받는다(통합본 1-1).
     *
     * 공지 첨부파일처럼 `window.open`으로 열린 창이 내려받기만 하고 그린 페이지가 없으면 Dart가
     * `download` 이벤트를 받고 그 창을 닫는다(`page_load.dart` `closeWindowAfterDownload`).
     */
    private fun downloadListener(id: Long) = DownloadListener {
            url, userAgent, contentDisposition, mimeType, _ ->
        event(id, "download", url)
        val download = { enqueueDownload(url, userAgent, contentDisposition, mimeType) }
        val write = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            ContextCompat.checkSelfPermission(activity, write) != PackageManager.PERMISSION_GRANTED
        ) {
            activity.requestStoragePermission(download)
        } else {
            download()
        }
    }

    private fun enqueueDownload(url: String, userAgent: String, contentDisposition: String, mimeType: String) {
        try {
            val request = DownloadManager.Request(Uri.parse(url))
            val manager = activity.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            val parts = javaSplit(
                URLDecoder.decode(contentDisposition, "UTF-8").replace("attachment; filename=", ""),
                "=",
            )
            val fileName = parts[parts.size - 1].replace("\"", "")
                .replace(Regex("\\p{Z}"), "_").replace(";", "")
            request.setMimeType(mimeType)
            request.addRequestHeader("cookie", CookieManager.getInstance().getCookie(url))
            request.addRequestHeader("User-Agent", userAgent)
            request.setDescription("파일을 내려받는 중입니다") // 원본 "Downloading File"(통합본 7-1)
            request.setAllowedOverMetered(true)
            request.setAllowedOverRoaming(true)
            request.setTitle(fileName)
            request.setRequiresCharging(false)
            @Suppress("DEPRECATION")
            request.allowScanningByMediaScanner()
            request.setAllowedOverMetered(true)
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
            manager.enqueue(request)
            Toast.makeText(activity.applicationContext, "파일이 다운로드됩니다.", Toast.LENGTH_LONG).show()
        } catch (_: Exception) {
            Toast.makeText(activity.baseContext, "파일을 내려받지 못했습니다.", Toast.LENGTH_LONG).show()
        }
    }

    /**
     * 링크 처리만 원본대로 하고 나머지는 플러그인 클라이언트(Dart 이벤트)로 넘긴다.
     * 본문 이동 시작(navigate), 방문 기록 갱신(committed), 첫 화면(visible)은 따로 알린다.
     * navigate의 `byUser`는 사용자가 누른 이동인지(서버 리디렉션·스크립트 이동이 아님)다.
     */
    private inner class ShellWebViewClient(
        private val id: Long,
        private val kind: String,
        private val inner: WebViewClient,
    ) : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            if (overrideUrl(kind, request.url.toString())) return true
            val handled = inner.shouldOverrideUrlLoading(view, request)
            if (!handled && request.isForMainFrame) {
                val byUser = request.hasGesture() && !request.isRedirect
                event(id, "navigate", request.url.toString(), mapOf("byUser" to byUser))
            }
            return handled
        }

        @Deprecated("Deprecated in Java")
        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
            if (overrideUrl(kind, url)) return true
            @Suppress("DEPRECATION")
            return inner.shouldOverrideUrlLoading(view, url)
        }

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) =
            inner.onPageStarted(view, url, favicon)

        override fun onPageFinished(view: WebView, url: String) {
            view.evaluateJavascript(ALLOW_ZOOM_SCRIPT, null)
            inner.onPageFinished(view, url)
        }

        override fun onLoadResource(view: WebView, url: String) = inner.onLoadResource(view, url)

        override fun onPageCommitVisible(view: WebView, url: String) {
            view.evaluateJavascript(ALLOW_ZOOM_SCRIPT, null)
            inner.onPageCommitVisible(view, url)
            event(id, "visible", url)
        }

        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
            inner.shouldInterceptRequest(view, request)

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) =
            inner.onReceivedError(view, request, error)

        @Deprecated("Deprecated in Java")
        override fun onReceivedError(view: WebView, errorCode: Int, description: String?, failingUrl: String?) {
            @Suppress("DEPRECATION")
            inner.onReceivedError(view, errorCode, description, failingUrl)
        }

        override fun onReceivedHttpError(
            view: WebView,
            request: WebResourceRequest,
            errorResponse: WebResourceResponse,
        ) = inner.onReceivedHttpError(view, request, errorResponse)

        override fun onFormResubmission(view: WebView, dontResend: Message, resend: Message) =
            inner.onFormResubmission(view, dontResend, resend)

        override fun doUpdateVisitedHistory(view: WebView, url: String, isReload: Boolean) {
            inner.doUpdateVisitedHistory(view, url, isReload)
            event(id, "committed", url)
        }

        override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: SslError) =
            inner.onReceivedSslError(view, handler, error)

        override fun onReceivedClientCertRequest(view: WebView, request: ClientCertRequest) =
            inner.onReceivedClientCertRequest(view, request)

        override fun onReceivedHttpAuthRequest(view: WebView, handler: HttpAuthHandler, host: String, realm: String) =
            inner.onReceivedHttpAuthRequest(view, handler, host, realm)

        override fun shouldOverrideKeyEvent(view: WebView, event: KeyEvent): Boolean =
            inner.shouldOverrideKeyEvent(view, event)

        override fun onUnhandledKeyEvent(view: WebView, event: KeyEvent) = inner.onUnhandledKeyEvent(view, event)

        override fun onScaleChanged(view: WebView, oldScale: Float, newScale: Float) =
            inner.onScaleChanged(view, oldScale, newScale)

        override fun onReceivedLoginRequest(view: WebView, realm: String, account: String?, args: String) =
            inner.onReceivedLoginRequest(view, realm, account, args)
    }

    /**
     * 팝업·자식·손자 창의 크롬 클라이언트. 새 창, 창 닫기, JS 알림창, 파일 선택은 원본대로 하고
     * 나머지는 플러그인 클라이언트로 넘긴다. 플러그인이 [WebChromeClientProxyApi.SecureWebChromeClient]만
     * 받으므로 그 클래스를 상속한다.
     *
     * 개선판은 메인 웹뷰에도 붙여 JS 알림창(alert/confirm)만 팝업과 같게 띄운다. 메인의 새 창·창
     * 닫기·파일 선택은 원본처럼 플러그인 클라이언트가 맡는다.
     */
    private inner class ShellChromeClient(
        private val id: Long,
        private val kind: String,
        private val inner: WebChromeClient,
    ) : WebChromeClientProxyApi.SecureWebChromeClient() {
        override fun onCreateWindow(view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message): Boolean {
            // 메인 웹뷰는 여러 창을 끄므로 불리지 않는다. 불리더라도 원본처럼 플러그인 클라이언트에 맡긴다.
            if (kind == "main") return inner.onCreateWindow(view, isDialog, isUserGesture, resultMsg)
            // 손자 창(원본 C0091f)은 새 창을 만들지 않는다.
            if (kind == "grandchild") return false
            val token = nextToken++
            pendingWindows[token] = resultMsg
            activity.invokeDart("createWindow", mapOf("parent" to kind, "token" to token))
            return true
        }

        override fun onCloseWindow(window: WebView) {
            if (kind == "child" || kind == "grandchild") {
                activity.invokeDart("closeWindow", id)
            } else {
                inner.onCloseWindow(window)
            }
        }

        override fun onJsAlert(view: WebView, url: String?, message: String?, result: JsResult): Boolean {
            // 원본은 로딩 표시(입력을 막는 창)를 먼저 걷었다. 개선판의 로딩 표시는 입력을 막지 않는다.
            // 원본은 뒤로 키에 확인으로 답만 하고 키를 먹어서 창이 닫히지 않았다(확인을 눌러야
            // 닫힘). 개선판은 뒤로 키로 창을 닫고 확인으로 한 번만 답한다. 바깥 터치로는 원본처럼
            // 닫히지 않는다. `확인`을 누르면 취소가 아니라 닫기라서 답이 두 번 가지 않는다.
            val dialog = AlertDialog.Builder(activity)
                .setTitle("")
                .setMessage(message)
                .setPositiveButton("확인") { _, _ -> result.confirm() }
                .setOnCancelListener { result.confirm() }
                .create()
            dialog.setCanceledOnTouchOutside(false)
            dialog.show()
            return true
        }

        override fun onJsConfirm(view: WebView, url: String?, message: String?, result: JsResult): Boolean {
            AlertDialog.Builder(activity)
                .setTitle("")
                .setMessage(message)
                .setPositiveButton("확인") { _, _ -> result.confirm() }
                .setNegativeButton("취소") { _, _ -> result.cancel() }
                // 원본은 뒤로 키·바깥 터치로 닫으면 페이지에 답하지 않아, 페이지가 답을 기다린 채 멈출 수 있었다.
                .setOnCancelListener { result.cancel() }
                .create()
                .show()
            return true
        }

        override fun onShowFileChooser(
            webView: WebView,
            filePathCallback: ValueCallback<Array<Uri>>,
            fileChooserParams: FileChooserParams,
        ): Boolean {
            // 손자 창(원본 C0091f)에는 파일 선택이 없다. 메인 웹뷰도 원본처럼 플러그인 클라이언트에 맡긴다.
            if (kind == "grandchild") return false
            if (kind == "main") return inner.onShowFileChooser(webView, filePathCallback, fileChooserParams)
            // 원본은 여기서 `파일 선택창을 선택하였습니다.` 토스트를 띄웠다. 개선판은 없앴다(통합본 7-2).
            activity.fileChooserCallback?.onReceiveValue(null)
            activity.fileChooserCallback = filePathCallback
            val intent = Intent(Intent.ACTION_GET_CONTENT)
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            intent.addCategory(Intent.CATEGORY_OPENABLE)
            intent.type = "*/*"
            @Suppress("DEPRECATION")
            activity.startActivityForResult(Intent.createChooser(intent, "파일 선택"), MainActivity.REQUEST_FILE_CHOOSER)
            return true
        }

        override fun onProgressChanged(view: WebView, newProgress: Int) = inner.onProgressChanged(view, newProgress)

        override fun onReceivedTitle(view: WebView, title: String?) = inner.onReceivedTitle(view, title)

        override fun onShowCustomView(view: View, callback: CustomViewCallback) = inner.onShowCustomView(view, callback)

        override fun onHideCustomView() = inner.onHideCustomView()

        override fun onJsPrompt(
            view: WebView,
            url: String?,
            message: String?,
            defaultValue: String?,
            result: JsPromptResult,
        ): Boolean = inner.onJsPrompt(view, url, message, defaultValue, result)

        override fun onJsBeforeUnload(view: WebView, url: String?, message: String?, result: JsResult): Boolean =
            inner.onJsBeforeUnload(view, url, message, result)

        override fun onGeolocationPermissionsShowPrompt(origin: String, callback: GeolocationPermissions.Callback) =
            inner.onGeolocationPermissionsShowPrompt(origin, callback)

        override fun onGeolocationPermissionsHidePrompt() = inner.onGeolocationPermissionsHidePrompt()

        override fun onPermissionRequest(request: PermissionRequest) = inner.onPermissionRequest(request)

        override fun onPermissionRequestCanceled(request: PermissionRequest) =
            inner.onPermissionRequestCanceled(request)

        override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean = inner.onConsoleMessage(consoleMessage)

        override fun getDefaultVideoPoster(): Bitmap? = inner.defaultVideoPoster

        override fun getVideoLoadingProgressView(): View? = inner.videoLoadingProgressView

        override fun getVisitedHistory(callback: ValueCallback<Array<String>>) = inner.getVisitedHistory(callback)

        override fun onRequestFocus(view: WebView) = inner.onRequestFocus(view)
    }

    companion object {
        /**
         * 학교 페이지 대부분이 viewport에 `user-scalable=no`를 넣어 확대를 막는다(통합본 5-2).
         * 첫 화면과 페이지 끝에서 viewport의 확대 금지·최대 배율만 바꿔 두 손가락 확대를 허용한다.
         */
        private val ALLOW_ZOOM_SCRIPT = """
            (function () {
              var metas = document.querySelectorAll('meta[name="viewport"]');
              for (var i = 0; i < metas.length; i++) {
                var content = metas[i].getAttribute('content') || '';
                var next = content
                  .replace(/user-scalable\s*=\s*(no|0)/gi, 'user-scalable=yes')
                  .replace(/maximum-scale\s*=\s*[0-9.]+/gi, 'maximum-scale=5');
                if (next !== content) metas[i].setAttribute('content', next);
              }
            })();
        """.trimIndent()

        /** Java `String.split(regex)`처럼 끝의 빈 문자열을 버린다. */
        fun javaSplit(value: String, delimiter: String): List<String> {
            if (!value.contains(delimiter)) return listOf(value)
            return value.split(delimiter).dropLastWhile { it.isEmpty() }
        }
    }
}
