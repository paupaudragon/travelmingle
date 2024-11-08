import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Flutter-Django Example")),
        body: const Center(child: FetchData()),
      ),
    );
  }
}

class FetchData extends StatefulWidget {
  const FetchData({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FetchDataState createState() => _FetchDataState();
}

class _FetchDataState extends State<FetchData> {
  String message = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchMessage();
  }

  fetchMessage() async {
    try {
      final response =
          await http.get(Uri.parse("http://10.0.2.2:8000/api/hello/"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          message = data['message'];
        });
      } else {
        setState(() {
          message = "Failed to load data";
        });
        print("Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() {
        message = "Failed to load data";
      });
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetch Data Example'),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}
