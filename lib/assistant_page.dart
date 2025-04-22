import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import '../services/firestore_service.dart';
import 'package:dash_chat_2/dash_chat_2.dart' as dash;
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'package:intl/intl.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> with SingleTickerProviderStateMixin {
  final Gemini gemini = Gemini.instance;
  final FirestoreService _firestoreService = FirestoreService();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  bool isTyping = false;
  
  // Initialize controller and animation immediately instead of using late
  AnimationController? _animationController;
  Animation<double> _fadeAnimation = AlwaysStoppedAnimation(1.0);

  // Sample greeting messages
  final List<String> greetings = [
    "Hello! I'm your NutriGuide assistant. How can I help with your nutrition journey today?",
    "Hi there! Need help with meal planning, nutritional information, or cooking tips?",
    "Welcome! I can provide nutritional advice, recipe suggestions, or answer your diet questions.",
    "Greetings! I'm here to help you make smart food choices. What would you like to know?",
    "Hi! Ask me anything about nutrition, diet plans, or healthy eating habits."
  ];

  ChatUser currentUser = ChatUser(
    id: "0", 
    firstName: "User",
  );
  
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Nutri Assistant",
    profileImage: "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Set the animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeIn,
      ),
    );
    
    // Start the animation
    _animationController!.forward();
    
    // Load chat history
    _loadChatHistory();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_NutriGuide.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8),
            Text(
              "Nutri Assistant",
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    // If no messages, add a welcome message
    if (messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          messages = _createWelcomeMessage();
        });
      });
    }
    
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
        containerColor: AppColors.surface,
        currentUserContainerColor: AppColors.primary,
        textColor: AppColors.text,
        currentUserTextColor: Colors.white,
        showTime: true,
        borderRadius: 16,
        messagePadding: const EdgeInsets.all(12),
        maxWidth: MediaQuery.of(context).size.width * 0.75,
        messageTextBuilder: (message, previousMessage, nextMessage) {
          return SelectableText(
            message.text,
            style: TextStyle(
              color: message.user.id == currentUser.id 
                ? Colors.white 
                : AppColors.text,
              fontSize: 16,
            ),
          );
        },
      ),
      inputOptions: InputOptions(
        inputDecoration: InputDecoration(
          hintText: "Ask about nutrition, recipes, or diet...",
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        inputTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        sendButtonBuilder: (onPressed) {
          return GestureDetector(
            onTap: onPressed,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
        leading: [
          isTyping
            ? Container(
                padding: const EdgeInsets.all(10),
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : IconButton(
                icon: Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () {},
              ),
        ],
      ),
      messageListOptions: MessageListOptions(
        showDateSeparator: true,
        dateSeparatorBuilder: (date) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                DateFormat('MMM dd, yyyy').format(date),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/logo_NutriGuide.png',
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading your nutrition assistant...",
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  List<ChatMessage> _createWelcomeMessage() {
    // Select a random greeting message
    final greeting = greetings[DateTime.now().microsecond % greetings.length];
    
    return [
      ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: greeting,
      ),
    ];
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
      isTyping = true;
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
          setState(() {
            isTyping = false;
          });
          // Simpan respons lengkap setelah streaming selesai
          if (messages.isNotEmpty && messages.first.user == geminiUser) {
            _firestoreService.saveChatMessage(messages.first, false);
          }
        },
      );
    } catch (e) {
      setState(() {
        isTyping = false;
      });
      print('Error in sendMessage: $e');
      
      // Show error message in chat
      dash.ChatMessage errorMessage = dash.ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: "I'm sorry, I couldn't process your request. Please try again later.",
      );
      setState(() {
        messages = [errorMessage, ...messages];
      });
    }
  }
}
