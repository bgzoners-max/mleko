package com.mleko.mleko

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		// Opt in on older Android versions too, matching Android 15 default behavior.
		enableEdgeToEdge()
		super.onCreate(savedInstanceState)
	}
}
