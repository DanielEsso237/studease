import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';

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

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Es-tu sûr de vouloir te déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Se déconnecter",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthService.logout();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        width: 260,
        color: Colors.white,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
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

            // ── Nouvelle conversation ────────────────────────────────────────
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

            // ── Liste des conversations ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      conversations[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selectedIndex == index,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),

            // ── Bouton Déconnexion ───────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text(
                    "Se déconnecter",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
