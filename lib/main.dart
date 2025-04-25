import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
Future<void> _sendToLaravel(String recognizedText) async {
  final String apiUrl = 'http://127.0.0.1:8000/api/voice'; // Ganti dengan URL API Laravel Anda

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
	print('Respond Body: ${response.body}');
    final Map<String, dynamic> responseData = json.decode(response.body);
    final String chatGPTResponse = responseData['answered'];
    setState(() {
      _recognizedText = chatGPTResponse;
    });
  } else {
    print('Failed to send data to Laravel: ${response.statusCode}');
  }
}
  

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          // Restart listening for continuous mode
          _startListening();
        }
      },
      onError: (error) {
        print('Speech error: $error');
      },
    );
  }

  void _startListening() {
    _speech.listen(
	  localeId: 'id_ID', // Bahasa Indonesia	
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
		  print('_recognizedText: ${_recognizedText}');
		  _sendToLaravel(_recognizedText);		  
        });
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );

    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
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
