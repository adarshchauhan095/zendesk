import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zen_ex/zendesk_answer.dart';
import 'package:zen_ex/zendesk_chat.dart';
import 'package:zendesk2/zendesk2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme:
              ColorScheme.fromSwatch().copyWith(secondary: Colors.green)),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  final z = Zendesk.instance;

  String accountKey = 'zOYANLFgvyQGJNERHM9UlzpwDopBWAPk';
  String appId = '11d00a1e09134eddb7652538d5fce59c6e37e001890f4b16';
  String clientId = 'mobile_sdk_client_fbad22aa872d3c0305e7';
  String zendeskUrl = 'https://yummysupport.zendesk.com';

  void answer() async {
    z.initAnswerSDK(appId, clientId, zendeskUrl);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const ZendeskAnswerUI()));
  }

  void chat({String? name, String? email, String? phoneNumber}) async {
    // String name = 'Adarsh';
    // String email = 'adarsh@appscrip.co';
    // String phoneNumber = '+917015027886';

    debugPrint('name: $name, email: $email, phoneNumber: $phoneNumber');

    await z.initChatSDK(accountKey, appId);

    Zendesk2Chat zChat = Zendesk2Chat.instance;

    await zChat.setVisitorInfo(
      name: name!,
      email: email!,
      phoneNumber: phoneNumber!,
      tags: ['app', 'zendesk2_plugin'],
    );

    await Zendesk2Chat.instance.startChatProviders(autoConnect: true);

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const ZendeskChat()));
  }

  String? n;
  String? e;
  String? p;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zendex App Example'),
        actions: [
          IconButton(
            onPressed: answer,
            icon: const Icon(Icons.question_answer),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text('Name'),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  n = val;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Email'),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
              onChanged: (val) {
                setState(() {
                  e = val;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Phone Number'),
            const SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
              onChanged: (val) {
                setState(() {
                  p = val;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: 'chat',
            icon: const Icon(FontAwesomeIcons.comments),
            label: const Text('Lets Chat...'),
            onPressed: () {
              chat(email: e, name: n, phoneNumber: p);
            },
          ),
        ],
      ),
    );
  }
}
