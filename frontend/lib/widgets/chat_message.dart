import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  static Widget _botAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          'assets/images/bot.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffE5E5EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(text, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _botAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 15, height: 1.5),
                strong: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                listBullet: const TextStyle(fontSize: 15, height: 1.5),
                code: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey.shade200,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              shrinkWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
