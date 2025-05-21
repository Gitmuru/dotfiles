// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  // Load environment variables from .env file (you'll need to create this)
  await dotenv.dotenv.load(fileName: ".env");
  runApp(const MindfulChatApp());
}

class MindfulChatApp extends StatelessWidget {
  const MindfulChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return MaterialApp(
      title: 'Mindful Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6A8CAF),
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A8CAF),
          secondary: const Color(0xFF83BCFF),
          tertiary: const Color(0xFFA2D6F9),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late AnimationController _typingController;
  final ScrollController _scrollController = ScrollController();
  
  // Wellness tips to show in the app
  final List<String> _wellnessTips = [
    "Take a few deep breaths when feeling stressed",
    "Remember to drink water throughout the day",
    "Take short breaks to rest your mind",
    "Practice gratitude by noting three good things daily",
    "Try to get 7-8 hours of sleep tonight",
    "A short walk can boost your mood significantly"
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    // Add initial welcome message
    _addMessage(
      "Hi there! I'm your wellness companion. How are you feeling today?",
      false,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to send message to Chatling API
  Future<void> _sendMessageToChatling(String message) async {
    final apiKey = dotenv.dotenv.env['CHATLING_API_KEY'] ?? '';
    final url = dotenv.dotenv.env['CHATLING_API_URL'] ?? 'https://api.chatling.ai/v1/chat';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'message': message,
          'model': 'default', // Adjust based on Chatling's API requirements
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['response'] ?? "I'm having trouble responding right now. Let's try again.";
        
        setState(() {
          _isLoading = false;
          _addMessage(aiResponse, false);
        });
      } else {
        setState(() {
          _isLoading = false;
          _addMessage("I'm having trouble connecting. Please check your internet connection and try again.", false);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _addMessage("I'm having trouble connecting. Please check your internet connection and try again.", false);
      });
    }
  }

  void _handleSubmit() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    _addMessage(message, true);
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API delay for demo purposes
    // Replace this with actual API call in production
    Future.delayed(const Duration(seconds: 2), () {
      // For demo purposes, use mock responses
      // In production, use: _sendMessageToChatling(message);
      _mockResponse(message);
    });
  }
  
  // Mock response function for demo purposes
  void _mockResponse(String message) {
    String response = "";
    message = message.toLowerCase();
    
    if (message.contains("hello") || message.contains("hi")) {
      response = "Hi there! How are you feeling today?";
    } else if (message.contains("sad") || message.contains("depress")) {
      response = "I'm sorry to hear you're feeling down. Remember that it's okay to feel this way sometimes. Would you like to try a quick breathing exercise?";
    } else if (message.contains("anxious") || message.contains("stress")) {
      response = "Anxiety can be challenging. Let's try grounding ourselves - can you name 5 things you can see right now?";
    } else if (message.contains("happy") || message.contains("good")) {
      response = "I'm glad you're feeling well! What's something that contributed to your positive mood today?";
    } else if (message.contains("tired") || message.contains("exhausted")) {
      response = "Rest is important! Have you been able to take breaks today? Even a short 5-minute pause can help restore your energy.";
    } else {
      response = "Thank you for sharing. How does that make you feel? Remember I'm here to listen and support you.";
    }
    
    setState(() {
      _isLoading = false;
      _addMessage(response, false);
    });
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
      ));
    });
    
    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F8FC),
                ),
                child: _buildMessageList(),
              ),
            ),
            _buildWellnessTipCard(),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF83BCFF), Color(0xFF6A8CAF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mindful Chat",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  "Your wellness companion",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF718096)),
            onPressed: () {
              // Open settings or more options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      padding: const EdgeInsets.symmetric(vertical: 15),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildLoadingBubble();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(5),
                  bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF2D3748),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isUser) 
            CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF6A8CAF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF83BCFF), Color(0xFF6A8CAF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                _buildTypingDot(100),
                _buildTypingDot(200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int millisecondDelay) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 10 * (0.5 + 0.5 * _typingController.value),
          width: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

 Widget _buildWellnessTipCard() {
231:     // Display a random wellness tip
232:     final String tip = _wellnessTips[Random().nextInt(_wellnessTips.length)]; // <-- Replace this line
233:     
234:     return Container(
235:       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
236:       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
237:       decoration: BoxDecoration(
238:         gradient: const LinearGradient(
239:           colors: [Color(0xFFA2D6F9), Color(0xFF83BCFF)],
240:           begin: Alignment.topLeft,
241:           end: Alignment.bottomRight,
242:         ),
243:         borderRadius: BorderRadius.circular(16),
244:         boxShadow: [
245:           BoxShadow(
246:             color: const Color(0xFF83BCFF).withOpacity(0.3),
247:             blurRadius: 10,
248:             offset: const Offset(0, 4),
249:           ),
250:         ],
251:       ),
252:       child: Row(
253:         children: [
254:           const Icon(
255:             Icons.lightbulb_outline,
256:             color: Colors.white,
257:           ),
258:           const SizedBox(width: 12),
259:           Expanded(
260:             child: Text(
261:               tip,
262:               style: const TextStyle(
263:                 color: Colors.white,
264:                 fontSize: 14,
265:               ),
266:             ),
267:           ),
268:         ],
269:       ),
270:     );
271:   }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                // Show emoji picker
              },
            ),
          ),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _handleSubmit,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF83BCFF), Color(0xFF6A8CAF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF83BCFF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// CREATE A .env FILE IN THE ROOT OF YOUR PROJECT WITH:
// CHATLING_API_KEY=your_api_key_here
// CHATLING_API_URL=https://api.chatling.ai/v1/chat

// ADD THESE DEPENDENCIES TO YOUR pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  http: ^0.13.5
  flutter_dotenv: ^5.0.2
  intl: ^0.18.0
  lottie: ^2.3.2
*/