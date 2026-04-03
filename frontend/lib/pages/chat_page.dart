import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/thinking_indicator.dart';
import '../widgets/chat_sidebar.dart';
import '../models/conv_summary.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ConvSummary> _conversations = [];
  int? _currentConvId;

  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showSidebar = false;

  String _username = '';
  late String _greeting;

  static const List<String> _greetings = [
    "Salut {name} ! On commence par quoi aujourd'hui ?",
    "Bonjour {name} ! Je suis prêt à t'aider 😊",
    "Content de te revoir, {name} ! Qu'est-ce qu'on explore aujourd'hui ?",
    "Hey {name} ! Une question sur la fac ou un cours à réviser ?",
    "Bienvenue {name} ! Pose-moi ta question, je suis tout ouïe 🎓",
  ];

  String get _personalizedGreeting => _greeting.replaceAll('{name}', _username);

  @override
  void initState() {
    super.initState();
    _greeting = _greetings[Random().nextInt(_greetings.length)];
    _loadUsername();
    _fetchConversations();
  }

  Future<void> _loadUsername() async {
    final name = await AuthService.getUserName();
    if (mounted) setState(() => _username = name ?? 'toi');
  }

  Future<String?> _authHeader() async {
    final token = await AuthService.getToken();
    return token != null ? 'Bearer $token' : null;
  }

  Future<void> _fetchConversations() async {
    final auth = await _authHeader();
    if (auth == null) return;
    try {
      final res = await http
          .get(
            Uri.parse(AppConfig.conversationsUrl),
            headers: {'Authorization': auth},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        await AuthService.handleUnauthorized(context);
        return;
      }
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _conversations = list.map((j) => ConvSummary.fromJson(j)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadConversation(ConvSummary conv) async {
    final auth = await _authHeader();
    if (auth == null) return;
    try {
      final res = await http
          .get(
            Uri.parse(AppConfig.messagesUrl(conv.id)),
            headers: {'Authorization': auth},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        await AuthService.handleUnauthorized(context);
        return;
      }
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _currentConvId = conv.id;
            _isLoading = false;
            _messages.clear();
            _messages.addAll(
              list.map<Map<String, String>>(
                (m) => {
                  'role': m['role'] as String,
                  'content': m['content'] as String,
                },
              ),
            );
            _showSidebar = false;
          });
          await Future.delayed(const Duration(milliseconds: 100));
          _scrollToBottom(animate: false);
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteConversation(ConvSummary conv) async {
    final auth = await _authHeader();
    if (auth == null) return;
    await http.delete(
      Uri.parse(AppConfig.deleteConvUrl(conv.id)),
      headers: {'Authorization': auth},
    );
    if (_currentConvId == conv.id) {
      setState(() {
        _messages.clear();
        _currentConvId = null;
      });
    }
    _fetchConversations();
  }

  Future<void> _renameConversation(ConvSummary conv, String newTitle) async {
    final auth = await _authHeader();
    if (auth == null) return;
    await http.put(
      Uri.parse(AppConfig.renameConvUrl(conv.id)),
      headers: {'Authorization': auth, 'Content-Type': 'application/json'},
      body: jsonEncode({'title': newTitle}),
    );
    _fetchConversations();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(max);
    }
  }

  void _toggleSidebar() => setState(() => _showSidebar = !_showSidebar);

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentConvId = null;
      _showSidebar = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _controller.clear();

    final auth = await _authHeader();
    if (auth == null) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    final newAssistantIndex = _messages.length;
    _messages.add({'role': 'assistant', 'content': ''});

    try {
      final request = http.Request('POST', Uri.parse(AppConfig.chatUrl));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = auth;
      request.body = jsonEncode({
        'message': text,
        'conversation_id': _currentConvId,
        'stream': true,
      });

      final response = await request.send();
      if (response.statusCode == 401) {
        await AuthService.handleUnauthorized(context);
        return;
      }
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      String buffer = '';

      response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              buffer += chunk;
              while (true) {
                final lb = buffer.indexOf('\n');
                if (lb == -1) break;
                final line = buffer.substring(0, lb).trim();
                buffer = buffer.substring(lb + 1);

                if (line.isEmpty || !line.startsWith('data: ')) continue;
                final data = line.substring(6).trim();

                if (data == '[DONE]') {
                  setState(() => _isLoading = false);
                  _scrollToBottom();
                  _fetchConversations();
                  return;
                }

                try {
                  final json = jsonDecode(data);

                  if (json.containsKey('conversation_id') &&
                      _currentConvId == null) {
                    _currentConvId = json['conversation_id'] as int;
                    return;
                  }

                  final delta =
                      json['choices']?[0]?['delta']?['content'] as String?;
                  if (delta != null && delta.isNotEmpty) {
                    setState(() {
                      _messages[newAssistantIndex] = {
                        'role': 'assistant',
                        'content':
                            (_messages[newAssistantIndex]['content'] ?? '') +
                            delta,
                      };
                    });
                    _scrollToBottom();
                  }
                } catch (_) {}
              }
            },
            onDone: () {
              setState(() => _isLoading = false);
              _scrollToBottom();
              _fetchConversations();
            },
            onError: (error) {
              setState(() {
                _messages[newAssistantIndex] = {
                  'role': 'assistant',
                  'content': 'Erreur : $error',
                };
                _isLoading = false;
              });
            },
            cancelOnError: true,
          );
    } catch (e) {
      setState(() {
        _messages[newAssistantIndex] = {
          'role': 'assistant',
          'content': 'Erreur de connexion : $e',
        };
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyPlaceholder() {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height - kToolbarHeight - 100,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/bot.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _personalizedGreeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Pose-moi une question sur la fac, un cours,\nou une procédure administrative !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: ChatAppBar(onMenuPressed: _toggleSidebar),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _messages.isEmpty && !_isLoading
                    ? _buildEmptyPlaceholder()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const ThinkingIndicator();
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return ChatMessage(
                            text: msg['content'] ?? '',
                            isUser: isUser,
                          );
                        },
                      ),
              ),
              ChatInput(controller: _controller, onSend: _sendMessage),
            ],
          ),

          if (_showSidebar)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

          if (_showSidebar)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onTap: () {},
                child: ChatSidebar(
                  conversations: _conversations,
                  selectedConvId: _currentConvId,
                  onSelect: _loadConversation,
                  onDelete: _deleteConversation,
                  onRename: _renameConversation,
                  onNewChat: _startNewChat,
                  onClose: _toggleSidebar,
                  username: _username,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
