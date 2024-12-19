import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isSending = false;

  // メッセージ送信処理
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _firestore.collection('chatRooms').doc(widget.roomId).collection('messages').add({
        'text': _messageController.text.trim(),
        'sender': 'User', // ユーザー名（認証に基づいて変更する必要がある）
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('メッセージ送信に失敗しました: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // 画像のアップロード処理
  Future<void> _uploadImage(File image) async {
    try {
      final storageRef = _storage.ref().child('chat_images').child(DateTime.now().toString());
      final uploadTask = storageRef.putFile(image);

      final downloadUrl = await uploadTask.whenComplete(() => null).then((_) => storageRef.getDownloadURL());

      await _firestore.collection('chatRooms').doc(widget.roomId).collection('messages').add({
        'imageUrl': downloadUrl,
        'sender': 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('画像のアップロードに失敗しました: $e')));
    }
  }

  // 画像選択の処理（画像ピッカーを使う）
  Future<void> _selectImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 画像が選択された場合
      File selectedImage = File(image.path);
      await _uploadImage(selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャットルーム'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('メッセージがありません'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final text = message['text'];
                    final imageUrl = message['imageUrl'];

                    bool isCurrentUser = message['sender'] == 'User'; // 自分のメッセージかどうか

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // ここで日時とユーザー名の表示を削除
                              // メッセージの送信者は削除
                              // DateTimeやsenderを表示しない
                              SizedBox(height: 5),
                              // 画像がある場合に表示
                              if (imageUrl != null)
                                Image.network(imageUrl, width: 200, height: 200, fit: BoxFit.cover),
                              // メッセージテキスト
                              if (text != null)
                                Text(
                                  text,
                                  style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _selectImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
















