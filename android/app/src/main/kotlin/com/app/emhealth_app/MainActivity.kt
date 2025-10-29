package com.app.emhealth_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Suppress verbose media logs including SMPTE warnings
        suppressVerboseLogs()
    }
    
    private fun suppressVerboseLogs() {
        try {
            // Suppress common media-related verbose logs
            val logTags = arrayOf(
                "MediaCodec",
                "MediaExtractor", 
                "MediaMetadataRetriever",
                "ExoPlayer",
                "MediaPlayer",
                "MediaMuxer",
                "MediaCodecList",
                "ACodec",
                "OMXClient",
                "MediaDrm",
                "C2Component",
                "C2SoftVpxDec",
                "C2SoftAvcDec",
                "C2SoftHevcDec"
            )
            
            logTags.forEach { tag ->
                try {
                    // Set log level to ERROR to suppress verbose logs
                    Log.isLoggable(tag, Log.ERROR)
                } catch (e: Exception) {
                    // Ignore individual tag exceptions
                }
            }
        } catch (e: Exception) {
            // Ignore any exceptions during log configuration
        }
    }
}
