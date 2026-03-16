import 'package:flutter/material.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  bool isSidebarOpen = false;
  bool isTyping = false;

  List<String> conversations = ["Conversation 1"];
  int selectedConversation = 0;

  List<Map<String, dynamic>> messages = [
    {
      "text": "Bonjour, je suis Studease. Posez vos questions sur la faculté.",
      "isUser": false,
    },
  ];

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"text": text, "isUser": true});
      controller.clear();
      isTyping = true;
    });

    scrollToBottom();
    simulateStreaming();
  }

  void simulateStreaming() async {
    const response =
        "La faculté des sciences d'Ebolowa propose plusieurs filières comme Informatique, Mathématiques et Physique.";

    String current = "";

    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));

      current += response[i];

      setState(() {
        if (messages.isNotEmpty && messages.last["isUser"] == false) {
          messages.last["text"] = current;
        } else {
          messages.add({"text": current, "isUser": false});
        }
      });

      scrollToBottom();
    }

    setState(() {
      isTyping = false;
    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void newConversation() {
    setState(() {
      conversations.add("Conversation ${conversations.length + 1}");
      selectedConversation = conversations.length - 1;

      messages = [
        {
          "text":
              "Bonjour, je suis Studease. Posez vos questions sur la faculté.",
          "isUser": false,
        },
      ];
    });
  }

  void selectConversation(int index) {
    setState(() {
      selectedConversation = index;
      isSidebarOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F8),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          setState(() {
                            isSidebarOpen = true;
                          });
                        },
                      ),
                      const Spacer(),
                      Image.asset("assets/images/logo_appbar.png", height: 35),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemCount: messages.length + (isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const TypingIndicator();
                          }

                          final msg = messages[index];

                          return ChatMessage(
                            text: msg["text"],
                            isUser: msg["isUser"],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                ChatInput(controller: controller, onSend: sendMessage),
              ],
            ),
          ),
          if (isSidebarOpen)
            GestureDetector(
              onTap: () {
                setState(() {
                  isSidebarOpen = false;
                });
              },
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            left: isSidebarOpen ? 0 : -260,
            top: 0,
            bottom: 0,
            child: ChatSidebar(
              conversations: conversations,
              selectedIndex: selectedConversation,
              onSelect: selectConversation,
              onNewChat: newConversation,
              onClose: () {
                setState(() {
                  isSidebarOpen = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
