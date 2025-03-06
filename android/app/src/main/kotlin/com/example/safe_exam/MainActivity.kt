package com.example.safe_exam

import io.flutter.embedding.android.FlutterActivity
import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SCREEN_PINNING_CHANNEL = "screen_pinning"
    private val VOLUME_CONTROL_CHANNEL = "com.example.safe_exam/volume"
    private var isProtectionEnabled = false // Variabel untuk kontrol halaman tertentu
    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Channel untuk Screen Pinning
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, SCREEN_PINNING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPinning" -> {
                    startPinning()
                    result.success("Screen Pinning started")
                }
                "stopPinning" -> {
                    stopPinning()
                    result.success("Screen Pinning stopped")
                }
                "isPinned" -> {
                    result.success(isScreenPinned())
                }
                "enableProtection" -> { // Aktifkan proteksi tombol di halaman tertentu
                    isProtectionEnabled = true
                    enableImmersiveMode()
                    result.success("Protection enabled")
                }
                "disableProtection" -> { // Matikan proteksi tombol
                    isProtectionEnabled = false
                    result.success("Protection disabled")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Channel untuk Kontrol Volume
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, VOLUME_CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "maximizeVolume" -> {
                    maximizeVolume()
                    result.success(null)
                }
                "playMaxVolumeSound" -> {
                    val soundPath = call.argument<String>("soundPath")
                    if (soundPath != null) {
                        playMaxVolumeSound(soundPath)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENT", "Sound path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        enableImmersiveMode()
    }

    // Fungsi untuk memaksimalkan volume
    private fun maximizeVolume() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Maksimalkan volume musik
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        audioManager.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            maxVolume,
            0
        )
    }

    // Fungsi untuk memainkan suara dengan volume maksimal
    private fun playMaxVolumeSound(soundPath: String) {
        try {
            // Hentikan pemutaran sebelumnya jika ada
            mediaPlayer?.release()
            
            // Inisialisasi MediaPlayer baru
            val assetManager = assets
            val descriptor = assetManager.openFd("flutter_assets/$soundPath")
            
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .setUsage(AudioAttributes.USAGE_ALARM) // Menggunakan USAGE_ALARM untuk prioritas tinggi
                        .build()
                )
                
                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                setVolume(1.0f, 1.0f) // Set volume ke maksimum
                prepare()
                start()
                
                setOnCompletionListener {
                    release()
                    mediaPlayer = null
                }
            }
        } catch (e: Exception) {
            println("Error playing sound: ${e.message}")
        }
    }

    private fun startPinning() {
        val activityManager = getSystemService(ActivityManager::class.java)
        if (activityManager?.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
            startLockTask()
        }
    }

    private fun stopPinning() {
        stopLockTask()
    }

    private fun isScreenPinned(): Boolean {
        val activityManager = getSystemService(ActivityManager::class.java)
        return activityManager?.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_PINNED
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus && isProtectionEnabled) {
            val closeSystemDialogs = Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS)
            sendBroadcast(closeSystemDialogs)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isProtectionEnabled && keyCode == KeyEvent.KEYCODE_BACK) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun enableImmersiveMode() {
        window.decorView.apply {
            systemUiVisibility = View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                    View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_FULLSCREEN
        }
    }

    override fun onDestroy() {
        // Bersihkan resources
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }
}