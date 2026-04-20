import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../pages/account_page.dart';
import '../models/conv_summary.dart';

class ChatSidebar extends StatefulWidget {
  final List<ConvSummary> conversations;
  final int? selectedConvId;
  final Function(ConvSummary) onSelect;
  final Function(ConvSummary) onDelete;
  final Function(ConvSummary, String) onRename;
  final VoidCallback onNewChat;
  final VoidCallback onClose;
  final VoidCallback onRefresh;
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
    required this.onRefresh,
    required this.username,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _initiale =>
      widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?';

  Color _avatarColor() {
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.green,
    ];
    if (widget.username.isEmpty) return Colors.grey;
    return colors[widget.username.codeUnitAt(0) % colors.length];
  }

  List<ConvSummary> get _filteredConversations {
    if (_searchQuery.isEmpty) return widget.conversations;
    final q = _searchQuery.toLowerCase();
    return widget.conversations
        .where((c) => c.title.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _showRenameDialog(ConvSummary conv) async {
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
    if (confirm != null && confirm.isNotEmpty) widget.onRename(conv, confirm);
  }

  Future<void> _confirmDelete(ConvSummary conv) async {
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
    if (confirm == true) widget.onDelete(conv);
  }

  Future<void> _logout() async {
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
    final filtered = _filteredConversations;

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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: ElevatedButton(
                onPressed: widget.onNewChat,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text("Nouvelle conversation"),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: "Rechercher…",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.blue.shade300,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "Aucune conversation"
                            : "Aucun résultat",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        final isSelected = conv.id == widget.selectedConvId;

                        final title = conv.title;
                        final qLower = _searchQuery.toLowerCase();
                        final matchIndex = _searchQuery.isEmpty
                            ? -1
                            : title.toLowerCase().indexOf(qLower);

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          title: matchIndex >= 0
                              ? RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: title.substring(0, matchIndex),
                                      ),
                                      TextSpan(
                                        text: title.substring(
                                          matchIndex,
                                          matchIndex + _searchQuery.length,
                                        ),
                                        style: TextStyle(
                                          backgroundColor:
                                              Colors.yellow.shade200,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: title.substring(
                                          matchIndex + _searchQuery.length,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => widget.onSelect(conv),
                          onLongPress: () => _showRenameDialog(conv),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () => _confirmDelete(conv),
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
                widget.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text(
                "Mon compte",
                style: TextStyle(fontSize: 12),
              ),
              onTap: () async {
                widget.onClose();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
                if (result == 'refresh') {
                  widget.onNewChat();
                  widget.onRefresh();
                }
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: _logout,
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
