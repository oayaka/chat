import 'package:chat/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login.dart'; // LoginScreenをインポート
import 'chatlist.dart'; // ChatListScreenをインポート
//import 'create_room.dart'; // CreateRoomScreenをインポート
import 'chat_room.dart'; // ChatRoomScreenをインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutterのバインディングを初期化
  await Firebase.initializeApp( // Firebaseの初期化
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // アプリの実行
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // 初期画面をLoginScreenに設定
      routes: {
          '/chatList': (context) => const ChatListScreen(),
          '/chatRoom': (context) => ChatRoomScreen(roomId: ModalRoute.of(context)!.settings.arguments as String), // roomIdを引数として渡す

            },

    );
  }
}








