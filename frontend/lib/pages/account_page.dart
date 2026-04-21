import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_messages.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'login_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _name = '';
  String _email = '';
  String _createdAt = '';
  bool _isLoading = true;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final data = await AccountService.getAccount();
    if (data != null && mounted) {
      final raw = data['created_at'] as String;
      final date = DateTime.tryParse(raw);
      final formatted = date != null
          ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
          : raw;
      setState(() {
        _name = data['name'] ?? '';
        _email = data['email'] ?? '';
        _createdAt = formatted;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      _showSnackBar(AppMessages.accountLoadError);
    }
  }

  String get _initiale => _name.isNotEmpty ? _name[0].toUpperCase() : '?';

  Color _avatarColor() {
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.green,
    ];
    if (_name.isEmpty) return Colors.grey;
    return colors[_name.codeUnitAt(0) % colors.length];
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le nom"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nouveau nom"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              final ok = await AccountService.updateUsername(newName);
              if (!mounted) return;
              if (ok) {
                await AuthService.saveSession(
                  token: (await AuthService.getToken())!,
                  name: newName,
                  email: _email,
                );
                setState(() => _name = newName);
                _showSnackBar(AppMessages.accountNameUpdated, isError: false);
              } else {
                _showSnackBar(AppMessages.accountNameError);
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Changer le mot de passe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: "Mot de passe actuel",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setLocal(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setLocal(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirmer le mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setLocal(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  _showSnackBar(AppMessages.registerPasswordMismatch);
                  return;
                }
                Navigator.pop(ctx);
                final error = await AccountService.updatePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!mounted) return;
                if (error == null) {
                  _showSnackBar(
                    AppMessages.accountPasswordUpdated,
                    isError: false,
                  );
                } else {
                  final friendly = _friendlyPasswordError(error);
                  _showSnackBar(friendly);
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyPasswordError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('actuel') || lower.contains('incorrect')) {
      return AppMessages.accountPasswordWrong;
    }
    if (lower.contains('différent') || lower.contains('different')) {
      return AppMessages.accountPasswordSame;
    }
    if (lower.contains('6') || lower.contains('caractère')) {
      return AppMessages.accountPasswordTooShort;
    }
    return raw;
  }

  void _showDeleteAllConversationsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Effacer toutes les discussions"),
        content: const Text(
          "Cette action supprimera définitivement toutes tes conversations. Elle est irréversible.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await AccountService.deleteAllConversations();
              if (!mounted) return;
              if (error == null) {
                _showSnackBar(
                  AppMessages.conversationsDeleteAllSuccess,
                  isError: false,
                );
                Navigator.pop(context, 'refresh');
              } else {
                _showSnackBar(AppMessages.conversationsDeleteAllError);
              }
            },
            child: const Text(
              "Tout supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Supprimer le compte"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cette action est irréversible. Toutes tes conversations seront supprimées.",
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "Confirme ton mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final error = await AccountService.deleteAccount(
                  controller.text,
                );
                if (!mounted) return;
                if (error == null) {
                  await AuthService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                } else {
                  final friendly = error.toLowerCase().contains('incorrect')
                      ? AppMessages.accountDeleteWrongPassword
                      : AppMessages.accountDeleteError;
                  _showSnackBar(friendly);
                }
              },
              child: const Text(
                "Supprimer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    String? trailing,
    Color? iconColor,
    Color? labelColor,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 22),
      title: Text(label, style: TextStyle(color: labelColor ?? Colors.black87)),
      trailing:
          trailingWidget ??
          (trailing != null
              ? Text(trailing, style: TextStyle(color: Colors.grey.shade500))
              : const Icon(Icons.chevron_right, color: Colors.grey)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon compte"),
        centerTitle: true,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 32),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: _avatarColor(),
                    child: Text(
                      _initiale,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    "Membre depuis le $_createdAt",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                _buildSection("Profil", [
                  _buildTile(
                    icon: Icons.edit_outlined,
                    label: "Modifier le nom",
                    onTap: _showEditNameDialog,
                  ),
                  _buildTile(
                    icon: Icons.lock_outline,
                    label: "Changer le mot de passe",
                    onTap: _showChangePasswordDialog,
                  ),
                ]),
                _buildSection("Préférences", [
                  _buildTile(
                    icon: Icons.dark_mode_outlined,
                    label: "Thème sombre",
                    trailingWidget: Switch(
                      value: _isDark,
                      onChanged: (val) {
                        setState(() => _isDark = val);
                        StudEaseApp.of(
                          context,
                        )?.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                    onTap: null,
                  ),
                ]),
                _buildSection("Gestion des données", [
                  _buildTile(
                    icon: Icons.delete_sweep_outlined,
                    label: "Effacer toutes les discussions",
                    iconColor: Colors.orange.shade700,
                    labelColor: Colors.orange.shade700,
                    trailingWidget: Icon(
                      Icons.chevron_right,
                      color: Colors.orange.shade700,
                    ),
                    onTap: _showDeleteAllConversationsDialog,
                  ),
                ]),
                _buildSection("À propos", [
                  _buildTile(
                    icon: Icons.info_outline,
                    label: "Version",
                    trailing: "version test (1.0.0)",
                    onTap: null,
                  ),
                  _buildTile(
                    icon: Icons.language,
                    label: "Site de la faculté",
                    onTap: () async {
                      final url = Uri.parse('https://www.univ-ebolowa.cm');
                      if (await canLaunchUrl(url)) launchUrl(url);
                    },
                  ),
                ]),
                _buildSection("Supprimer mon compte", [
                  _buildTile(
                    icon: Icons.delete_forever_outlined,
                    label: "Supprimer mon compte",
                    iconColor: Colors.red,
                    labelColor: Colors.red,
                    trailingWidget: const Icon(
                      Icons.chevron_right,
                      color: Colors.red,
                    ),
                    onTap: _showDeleteAccountDialog,
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
