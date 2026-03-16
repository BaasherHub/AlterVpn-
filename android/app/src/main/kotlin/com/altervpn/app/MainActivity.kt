package com.altervpn.app

import android.content.Intent
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Required by openvpn_flutter to complete VPN permission grant flow.
    // When the user approves the VPN permission dialog (request code 24),
    // we forward the result so the plugin can start the OpenVPN service.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        OpenVPNFlutterPlugin.connectWhileGranted(requestCode == 24 && resultCode == RESULT_OK)
        super.onActivityResult(requestCode, resultCode, data)
    }
}
