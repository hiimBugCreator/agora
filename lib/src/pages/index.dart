import 'dart:developer';

import 'package:agora/src/pages/call.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRole? _role = ClientRole.Broadcaster;

  static String channelName = "";
  static String token = "";

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // registerNotification();
    // FirebaseMessaging.onMessageOpenedApp.listen((event) async {
    //   print(event.data);
    //   // onJoin(channelName, token);
    //   if (event.data["roomId"].toString().isNotEmpty && event.data["token"].toString().isNotEmpty) {
    //     print("VKLopen");
    //     if (open)  {
    //       await Permission.camera.request();
    //       await Permission.microphone.request();
    //       await Navigator.push(
    //           context,
    //           MaterialPageRoute(
    //               builder: (context) => CallPage(
    //                 channelName: event.data["roomId"] ?? channelName,
    //                 token: event.data["token"] ?? token,
    //                 role: _role ?? ClientRole.Broadcaster,
    //               )));
    //       setState(() {
    //         token = event.data["token"] ?? token;
    //         channelName = event.data["roomId"] ?? channelName;
    //         // open = false;
    //       });
    //     }
    //   }
    // });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Image.network('https://tinyurl.com/2p889y4k'),
              Image.network(
                'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/b5881ea0-478f-4282-8592-f99945cc39c6/dba6nk6-a35902ca-a490-4f34-a36d-26fecd681616.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcL2I1ODgxZWEwLTQ3OGYtNDI4Mi04NTkyLWY5OTk0NWNjMzljNlwvZGJhNm5rNi1hMzU5MDJjYS1hNDkwLTRmMzQtYTM2ZC0yNmZlY2Q2ODE2MTYucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.B4ss2Ki6MaTO0PQH9mrT8EMXVSJbtsZDtxQAbQAuVL4',
                width: 500,
                height: 350,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _channelController,
                decoration: InputDecoration(
                  errorText: _validateError ? 'Chanel name is mandatory' : null,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                  hintText: 'Chanel name',
                ),
              ),
              RadioListTile(
                title: const Text("Broadcaster"),
                onChanged: (ClientRole? value) {
                  setState(() {
                    _role = value;
                  });
                },
                value: ClientRole.Broadcaster,
                groupValue: _role,
              ),
              RadioListTile(
                title: const Text("Audience"),
                onChanged: (ClientRole? value) {
                  setState(() {
                    _role = value;
                  });
                },
                value: ClientRole.Audience,
                groupValue: _role,
              ),
              ElevatedButton(
                onPressed: () {
                  onJoin(_channelController.text, token);
                },
                child: const Text("Join"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin(String channelName, String token) async {
    setState(() {
      _validateError = channelName.isEmpty ? true : false;
    });
    if (channelName.isNotEmpty) {
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                    channelName: channelName,
                    token: token,
                    role: _role,
                  )));
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}

class PushNotification {
  PushNotification({
    this.title,
    this.body,
  });

  String? title;
  String? body;
}
