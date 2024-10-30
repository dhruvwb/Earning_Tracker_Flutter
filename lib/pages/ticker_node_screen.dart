import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class TranscriptScreen extends StatefulWidget {
  final String priceDate;
  final String ticker;

  const TranscriptScreen(
      {Key? key, required this.priceDate, required this.ticker})
      : super(key: key);

  @override
  _TranscriptScreenState createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  String _transcript = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTranscript();
  }

  Future<void> fetchTranscript() async {
    final year = DateTime.now().year;
    // final quarter = (DateTime.now().month ~/ 3) + 1;
    final random = Random();

    // Generate a random quarter between 1 and 4
    final quarter =
        random.nextInt(3) + 1; // nextInt(4) generates 0 to 3, so we add 1

    // Print the year and quarter for debugging

    final url = Uri.parse(
        'https://api.api-ninjas.com/v1/earningstranscript?ticker=${widget.ticker}&year=$year&quarter=$quarter');

    final response = await http.get(
      url,
      headers: {'X-Api-Key': 'YOUR_API_KEY'},
    );

    // Print the status code of the response

    if (response.statusCode == 200) {
      setState(() {
        _transcript = jsonDecode(response.body)['transcript'];
        _isLoading = false;
      });
      // Print the transcript for debugging
    } else {
      setState(() {
        _transcript = 'Error fetching transcript';
        _isLoading = false;
      });
      // Print the error message
      print('Error fetching transcript: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Earnings Transcript')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // Wrap with SingleChildScrollView
                padding: const EdgeInsets.all(16.0),
                child: Text(_transcript),
              ),
      ),
    );
  }
}
