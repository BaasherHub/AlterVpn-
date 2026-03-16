package com.altervpn.app

import android.content.Intent
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Required by openvpn_flutter to complete VPN permission grant flow.
    // When the user approves the VPN permission dialog, we forward the result
    // so the plugin can start the OpenVPN service.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // Only forward VPN permission results to the plugin.
        // Passing false for unrelated activity results previously caused a
        // spurious "permission denied" state in the VPN engine.
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            OpenVPNFlutterPlugin.connectWhileGranted(resultCode == RESULT_OK)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    companion object {
        // Request code used by openvpn_flutter when asking for VPN permission.
        private const val VPN_PERMISSION_REQUEST_CODE = 24
    }
}
