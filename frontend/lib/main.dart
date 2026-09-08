import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Week14 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  final TextEditingController _accessCtrl = TextEditingController();
  final TextEditingController _refreshCtrl = TextEditingController();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _apiToken() async {
    final username = _usernameCtrl.text;
    final password = _passwordCtrl.text;
    
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _accessCtrl.text = data['access'];
          _refreshCtrl.text = data['refresh'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to backend: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('Enter username and password'),
            TextField(controller: _usernameCtrl),
            TextField(controller: _passwordCtrl, obscureText: true),
            const Text('Access/Refresh Token'),
            TextField(controller: _accessCtrl),
            TextField(controller: _refreshCtrl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _apiToken,
        tooltip: 'Access',
        child: const Icon(Icons.favorite),
      ),
    );
  }
}
