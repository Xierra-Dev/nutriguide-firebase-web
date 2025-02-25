import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../services/firestore_service.dart';
import 'package:dash_chat_2/dash_chat_2.dart' as dash;

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final Gemini gemini = Gemini.instance;
  final FirestoreService _firestoreService = FirestoreService();
  List<ChatMessage> messages = [];
  bool isLoading = true;

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Nutri Assistant",
    profileImage: "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Nutri Assistant",
        ),
      ),
      body: _buildUI(),
    );
  }

  // Tambahkan method _buildUI
  Widget _buildUI() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.deepOrange,
        ),
      );
    }
    
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
        containerColor: const Color(0xFF4CAF50),
        currentUserContainerColor: const Color(0xFF2196F3),
        textColor: Colors.white,
        currentUserTextColor: Colors.white,
        showTime: true,
        messagePadding: const EdgeInsets.all(10),
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        messageTextBuilder: (message, previousMessage, nextMessage) {
          return SelectableText(
            message.text,
            style: TextStyle(
              color: message.user.id == currentUser.id ? Colors.white : Colors.white,
            ),
          );
        },
      ),
      messageListOptions: MessageListOptions(
        showDateSeparator: true,
        scrollController: ScrollController(),
        chatFooterBuilder: Container(),
      ),
    );
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await _firestoreService.getChatHistory();
      setState(() {
        messages = history;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() => isLoading = false);
    }
  }

  void _sendMessage(dash.ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    
    try {
      await _firestoreService.saveChatMessage(chatMessage, true);

      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      String fullResponse = ""; // Tambahkan variabel untuk menyimpan respons lengkap
      
      gemini.streamGenerateContent(
        question,
        images: images,
      ).listen(
        (event) {
          dash.ChatMessage? lastMessage = messages.firstOrNull;
          String response = event.content?.parts?.fold(
              "", (previous, current) => "$previous ${current.text}") ?? "";
          
          if (lastMessage != null && lastMessage.user == geminiUser) {
            lastMessage = messages.removeAt(0);
            fullResponse += response; // Akumulasi respons
            lastMessage.text = fullResponse; // Gunakan respons lengkap
            setState(() {
              messages = [lastMessage!, ...messages];
            });
          } else {
            fullResponse = response; // Mulai respons baru
            dash.ChatMessage message = dash.ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );
            setState(() {
              messages = [message, ...messages];
            });
          }
        },
        onDone: () {
          // Simpan respons lengkap setelah streaming selesai
          if (messages.isNotEmpty && messages.first.user == geminiUser) {
            _firestoreService.saveChatMessage(messages.first, false);
          }
        },
      );
    } catch (e) {
      print('Error in sendMessage: $e');
    }
  }
}
