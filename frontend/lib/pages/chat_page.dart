import 'dart:async';
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
import '../widgets/question_suggestions.dart';
import '../models/conv_summary.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ConvSummary> _conversations = [];
  int? _currentConvId;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _showSidebar = false;
  bool _systemReady = false;

  Timer? _statusTimer;

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
    _fetchConversations(reset: true);
    _pollStatus();
  }

  Future<void> _pollStatus() async {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await http
            .get(
              Uri.parse(AppConfig.statusUrl),
              headers: {'ngrok-skip-browser-warning': 'true'},
            )
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['ready'] == true && mounted) {
            setState(() => _systemReady = true);
            _statusTimer?.cancel();
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadUsername() async {
    final name = await AuthService.getUserName();
    if (mounted) setState(() => _username = name ?? 'toi');
  }

  Future<void> _fetchConversations({bool reset = false}) async {
    if (_isLoadingMore) return;
    final headers = await AuthService.authHeaders();

    if (reset) {
      _currentPage = 1;
      _hasMore = false;
    }

    setState(() => _isLoadingMore = true);

    try {
      final uri = Uri.parse(
        AppConfig.conversationsUrl,
      ).replace(queryParameters: {'page': '$_currentPage', 'per_page': '20'});
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 401) {
        await AuthService.handleUnauthorized(context);
        return;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['conversations'];
        final bool hasNext = data['has_next'] ?? false;

        if (mounted) {
          setState(() {
            if (reset) {
              _conversations = list
                  .map((j) => ConvSummary.fromJson(j))
                  .toList();
            } else {
              _conversations.addAll(list.map((j) => ConvSummary.fromJson(j)));
            }
            _hasMore = hasNext;
            if (hasNext) _currentPage++;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadConversation(ConvSummary conv) async {
    final headers = await AuthService.authHeaders();
    try {
      final res = await http
          .get(Uri.parse(AppConfig.messagesUrl(conv.id)), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 401) {
        await AuthService.handleUnauthorized(context);
        return;
      }
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['messages'];
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
    final headers = await AuthService.authHeaders();
    await http.delete(
      Uri.parse(AppConfig.deleteConvUrl(conv.id)),
      headers: headers,
    );
    if (_currentConvId == conv.id) {
      setState(() {
        _messages.clear();
        _currentConvId = null;
      });
    }
    _fetchConversations(reset: true);
  }

  Future<void> _renameConversation(ConvSummary conv, String newTitle) async {
    final headers = await AuthService.authHeaders();
    await http.put(
      Uri.parse(AppConfig.renameConvUrl(conv.id)),
      headers: headers,
      body: jsonEncode({'title': newTitle}),
    );
    _fetchConversations(reset: true);
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
    if (text.isEmpty || !_systemReady) return;

    FocusScope.of(context).unfocus();
    _controller.clear();

    final headers = await AuthService.authHeaders();

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
      request.headers.addAll(headers);
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

      if (response.statusCode == 503) {
        setState(() {
          _messages.removeLast();
          _messages.removeLast();
          _isLoading = false;
          _systemReady = false;
        });
        _controller.text = text;
        _pollStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Système en cours de démarrage, patiente un instant…",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Erreur ${response.statusCode} - $body');
      }

      String buffer = '';

      response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              buffer += chunk;
              while (buffer.contains('\n\n')) {
                final idx = buffer.indexOf('\n\n');
                final event = buffer.substring(0, idx).trim();
                buffer = buffer.substring(idx + 2);

                if (event.isEmpty || !event.startsWith('data: ')) continue;

                final data = event.substring(6).trim();

                if (data == '[DONE]') {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    _scrollToBottom();
                    _fetchConversations(reset: true);
                  }
                  return;
                }

                try {
                  final parsed = jsonDecode(data);
                  if (parsed is Map && parsed.containsKey('conversation_id')) {
                    _currentConvId ??= parsed['conversation_id'] as int;
                    continue;
                  }
                  final delta =
                      parsed['choices']?[0]?['delta']?['content'] as String?;
                  if (delta != null && delta.isNotEmpty && mounted) {
                    setState(() {
                      final current =
                          _messages[newAssistantIndex]['content'] ?? '';
                      _messages[newAssistantIndex] = {
                        'role': 'assistant',
                        'content': current + delta,
                      };
                    });
                    _scrollToBottom();
                  }
                } catch (_) {}
              }
            },
            onDone: () {
              if (mounted) {
                setState(() => _isLoading = false);
                _scrollToBottom();
                _fetchConversations(reset: true);
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _messages[newAssistantIndex] = {
                    'role': 'assistant',
                    'content': 'Erreur : $error',
                  };
                  _isLoading = false;
                });
              }
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[newAssistantIndex] = {
            'role': 'assistant',
            'content': 'Erreur de connexion : $e',
          };
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmptyPlaceholder() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: QuestionSuggestions(
              onSuggestionTap: (question) {
                _controller.text = question;
                _sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: ChatAppBar(onMenuPressed: _toggleSidebar),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
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
                            return ChatMessage(
                              text: msg['content'] ?? '',
                              isUser: msg['role'] == 'user',
                            );
                          },
                        ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 0),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ChatInput(
                    controller: _controller,
                    onSend: _sendMessage,
                    isReady: _systemReady,
                  ),
                ),
              ],
            ),
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
                  onRefresh: () => _fetchConversations(reset: true),
                  username: _username,
                  hasMore: _hasMore,
                  onLoadMore: () => _fetchConversations(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
