package com.mmail.app

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val webView = WebView(this)

        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.webViewClient = WebViewClient()

        // YOUR LIVE FRONTEND
        webView.loadUrl("https://mmail-f64e9.web.app")

        val layout = LinearLayout(this)
        layout.addView(webView)

        setContentView(layout)
    }
}
