import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../pages/account_page.dart';
import '../models/conv_summary.dart';

class ChatSidebar extends StatelessWidget {
  final List<ConvSummary> conversations;
  final int? selectedConvId;
  final Function(ConvSummary) onSelect;
  final Function(ConvSummary) onDelete;
  final Function(ConvSummary, String) onRename;
  final VoidCallback onNewChat;
  final VoidCallback onClose;
  final String username;

  const ChatSidebar({
    super.key,
    required this.conversations,
    required this.selectedConvId,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
    required this.onNewChat,
    required this.onClose,
    required this.username,
  });

  String get _initiale => username.isNotEmpty ? username[0].toUpperCase() : '?';

  Color _avatarColor() {
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.green,
    ];
    if (username.isEmpty) return Colors.grey;
    return colors[username.codeUnitAt(0) % colors.length];
  }

  Future<void> _showRenameDialog(BuildContext context, ConvSummary conv) async {
    final controller = TextEditingController(text: conv.title);
    final confirm = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Renommer la conversation"),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: "Nouveau titre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Renommer"),
          ),
        ],
      ),
    );
    if (confirm != null && confirm.isNotEmpty) onRename(conv, confirm);
  }

  Future<void> _confirmDelete(BuildContext context, ConvSummary conv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer la conversation"),
        content: Text(
          "Supprimer « ${conv.title} » ?\nCette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) onDelete(conv);
  }

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
              child: conversations.isEmpty
                  ? Center(
                      child: Text(
                        "Aucune conversation",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final isSelected = conv.id == selectedConvId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          title: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onSelect(conv),
                          onLongPress: () => _showRenameDialog(context, conv),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () => _confirmDelete(context, conv),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: _avatarColor(),
                child: Text(
                  _initiale,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text(
                "Mon compte",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                onClose();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
