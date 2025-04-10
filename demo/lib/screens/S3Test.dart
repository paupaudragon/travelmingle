import 'package:demo/widgets/loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class S3TestPage extends StatefulWidget {
  const S3TestPage({Key? key}) : super(key: key);

  @override
  _S3TestPageState createState() => _S3TestPageState();
}

class _S3TestPageState extends State<S3TestPage> {
  String _resultText = '';
  bool _isLoading = false;
  final TextEditingController _urlController = TextEditingController(
    text:
        'https://travelmingle-media.s3.amazonaws.com/media/postImages/scaled_1000000033.jpg',
  );

  Future<void> _testDirectAccess() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Testing direct access...';
    });

    try {
      // Make a HEAD request first to get headers without downloading the full image
      final response = await http.head(Uri.parse(_urlController.text));

      String result = 'HEAD Request:\n';
      result += 'Status Code: ${response.statusCode}\n';
      result += 'Headers:\n';

      response.headers.forEach((key, value) {
        result += '$key: $value\n';
      });

      // If HEAD failed, make a GET request to get the error body
      if (response.statusCode != 200) {
        try {
          final getResponse = await http.get(Uri.parse(_urlController.text));
          result += '\nGET Response Body:\n';

          if (getResponse.headers['content-type']?.contains('xml') == true) {
            // Try to format XML for easier reading
            result += _formatXml(getResponse.body);

            // Extract error message if present
            if (getResponse.body.contains('<Message>')) {
              final messageStart = getResponse.body.indexOf('<Message>') + 9;
              final messageEnd = getResponse.body.indexOf('</Message>');
              if (messageStart > 0 && messageEnd > 0) {
                final errorMessage =
                    getResponse.body.substring(messageStart, messageEnd);
                result += '\nError Message: $errorMessage\n';
              }
            }

            // Extract request ID if present
            if (getResponse.body.contains('<RequestId>')) {
              final requestIdStart =
                  getResponse.body.indexOf('<RequestId>') + 11;
              final requestIdEnd = getResponse.body.indexOf('</RequestId>');
              if (requestIdStart > 0 && requestIdEnd > 0) {
                final requestId =
                    getResponse.body.substring(requestIdStart, requestIdEnd);
                result += 'Request ID: $requestId\n';
              }
            }
          } else {
            result += getResponse.body;
          }
        } catch (e) {
          result += '\nError making GET request: $e';
        }
      }

      setState(() {
        _resultText = result;
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatXml(String xml) {
    // Simple formatting for XML errors
    return xml.replaceAll('><', '>\n<');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'S3 URL to test',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectAccess,
              child: _isLoading
                  ? const LoadingAnimation()
                  : const Text('Test Access'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Results:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _resultText,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
