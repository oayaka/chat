import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャットルーム一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // ダイアログを表示
              showDialog(
                context: context,
                builder: (context) => const CreateRoomDialog(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('チャットルームがありません'));
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return ListTile(
                title: Text(chatRoom['roomName']),
                subtitle: Text(chatRoom['lastMessage'] ?? 'メッセージなし'),
                onTap: () {
                  Navigator.pushNamed(
                  context,
                  '/chatRoom',
                  arguments: chatRoom.id, // チャットルームのIDを渡す
                   );
                    },

              );
            },
          );
        },
      ),
    );
  }
}

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  _CreateRoomDialogState createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final TextEditingController _roomNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルーム名を入力してください')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await FirebaseFirestore.instance.collection('chatRooms').add({
        'roomName': _roomNameController.text.trim(),
        'lastMessage': null, // 初期状態ではメッセージなし
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(); // ダイアログを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルームが作成されました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ルームの作成に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新しいチャットルームを作成'),
      content: TextField(
        controller: _roomNameController,
        decoration: const InputDecoration(
          labelText: 'ルーム名',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createRoom,
          child: _isCreating
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('作成'),
        ),
      ],
    );
  }
}



