import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SpeechToTextExample());
  }
}

class SpeechToTextExample extends StatefulWidget {
  @override
  _SpeechToTextExampleState createState() => _SpeechToTextExampleState();
}

class _SpeechToTextExampleState extends State<SpeechToTextExample> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _hasSent = false;
  String _recognizedText = '';
  Timer? _silenceTimer;
  String _finalText = '';
  Timer? _repeatListeningTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Adjust speed
    await _flutterTts.setPitch(1.0);      // Adjust pitch
    await _flutterTts.speak(text);
	_startRepeatListening();	  
  }

  Future<void> _sendToLaravel(String recognizedText) async {
    final String apiUrl = 'http://127.0.0.1:8000/api/voice'; // Change with your backend URL

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'text': recognizedText,
      }),
    );

    if (response.statusCode == 200) {
      print('Response Body: ${response.body}');
      final Map<String, dynamic> responseData = json.decode(response.body);
      final String chatGPTResponse = responseData['answered'];
      setState(() {
        _recognizedText = chatGPTResponse;
      });
      await _speakText(chatGPTResponse);
    
    } else {
      print('Failed to send data to Laravel: ${response.statusCode}');
    }
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' && _isListening) {
          _stopListening();
        }
      },
	  onError: (error) {
		print('Speech error: $error');
		if (error.errorMsg == 'no-speech') {
		  // Ignore no-speech errors
		  return;
		}
		// Handle other errors if necessary
	  },
    );
  }

  Future<void> _startListening() async {
    final systemLocale = await _speech.systemLocale();
    _finalText = '';
    _hasSent = false; // Reset when start listening
    _speech.listen(
      localeId: systemLocale?.localeId ?? 'en_US',
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });

        if (result.finalResult && !_hasSent) {
          _hasSent = true;
          _finalText = result.recognizedWords;
          _stopListening();
          _sendToLaravel(_finalText);
          return;
        }

        // Reset silence timer
        _silenceTimer?.cancel();
        _silenceTimer = Timer(Duration(seconds: 2), () {
          if (!_hasSent) {
            _hasSent = true;
            print("User stopped speaking. Sending to Laravel...");
            _stopListening();
            _sendToLaravel(_finalText.isNotEmpty ? _finalText : _recognizedText);
          }
        });
      },
      listenFor: Duration(seconds: 60), // Duration before stopping
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );

    setState(() {
      _isListening = true;
    });

    // Start the auto-repeat mechanism after the session ends
  }

  void _stopListening() {
    _speech.stop();
    _silenceTimer?.cancel();
    setState(() {
      _isListening = false;
    });
    _repeatListeningTimer?.cancel(); // Cancel any active repeat listening timer
  }

  // Start the repeat listening process every X seconds (60 seconds for example)
  void _startRepeatListening() {
    _repeatListeningTimer = Timer.periodic(Duration(seconds: 60), (_) {
      if (!_isListening) {
        print("Restarting listening session...");
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _repeatListeningTimer?.cancel(); // Ensure this is canceled when the widget is disposed
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice to Text')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_recognizedText),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}
