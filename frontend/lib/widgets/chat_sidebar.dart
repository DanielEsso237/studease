import 'package:flutter/material.dart';

class ChatSidebar extends StatelessWidget {
  final List<String> conversations;
  final int selectedIndex;
  final Function(int) onSelect;
  final VoidCallback onNewChat;
  final VoidCallback onClose;

  const ChatSidebar({
    super.key,
    required this.conversations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onNewChat,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        width: 260,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                  const Spacer(),
                  const Text(
                    "Conversations",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: onNewChat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text("Nouvelle conversation"),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(conversations[index]),
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
