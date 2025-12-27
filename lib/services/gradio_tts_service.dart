import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GradioTtsService {
  final String baseUrl;

  GradioTtsService({this.baseUrl = 'http://localhost:7860'});

  /// Synthesize speech from text using the Gradio /gen_single endpoint
  /// Returns the path to the generated audio file
  Future<String?> synthesizeSpeech(String text) async {
    try {
      // Step 1: POST to initiate the request and get event ID
      final initResponse = await http.post(
        Uri.parse('$baseUrl/gradio_api/call/gen_single'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': [
            'Same as the voice reference', // [0] Emotion control method
            null, // [1] Voice Reference (use default)
            text, // [2] Text to synthesize
            null, // [3] Emotion reference audio
            0, // [4] Emotion control weight
            0, // [5] Happy
            0, // [6] Angry
            0, // [7] Sad
            0, // [8] Afraid
            0, // [9] Disgusted
            0, // [10] Melancholic
            0, // [11] Surprised
            0.5, // [12] Calm
            '', // [13] Emotion description
            true, // [14] Randomize emotion sampling
            20, // [15] Max tokens per generation segment
            true, // [16] do_sample
            0, // [17] top_p
            0, // [18] top_k
            0.1, // [19] temperature
            -2, // [20] length_penalty
            1, // [21] num_beams
            0.1, // [22] repetition_penalty
            50, // [23] max_mel_tokens
          ],
        }),
      );

      if (initResponse.statusCode != 200) {
        print('TTS init failed: ${initResponse.statusCode}');
        return null;
      }

      // Parse event ID from response
      final initData = jsonDecode(initResponse.body);
      final eventId = initData['event_id'] as String?;

      if (eventId == null) {
        print('No event ID received');
        return null;
      }

      // Step 2: GET the result using the event ID (SSE stream)
      final resultResponse = await http.get(
        Uri.parse('$baseUrl/gradio_api/call/gen_single/$eventId'),
      );

      if (resultResponse.statusCode != 200) {
        print('TTS result failed: ${resultResponse.statusCode}');
        return null;
      }

      // Parse the SSE response to get audio file info
      final audioUrl = _parseAudioUrl(resultResponse.body);
      if (audioUrl == null) {
        print('Could not parse audio URL from response');
        return null;
      }

      // Step 3: Download the audio file
      final audioPath = await _downloadAudio(audioUrl);
      return audioPath;
    } catch (e) {
      print('TTS error: $e');
      return null;
    }
  }

  /// Parse the SSE response to extract audio URL
  String? _parseAudioUrl(String sseResponse) {
    try {
      // SSE format: "event: ...\ndata: ..."
      final lines = sseResponse.split('\n');
      for (final line in lines) {
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5).trim();
          final data = jsonDecode(jsonStr);

          // The audio is in the first element of the response
          if (data is List && data.isNotEmpty) {
            final audioData = data[0];
            if (audioData is Map) {
              // Could be {url: "...", path: "..."}
              return audioData['url'] as String? ??
                  '$baseUrl/file=${audioData['path']}';
            }
          }
        }
      }
    } catch (e) {
      print('Parse error: $e');
    }
    return null;
  }

  /// Download audio from URL and save to temp file
  Future<String?> _downloadAudio(String audioUrl) async {
    try {
      final response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode != 200) return null;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/tts_$timestamp.wav');
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  /// Check if the TTS service is available
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
