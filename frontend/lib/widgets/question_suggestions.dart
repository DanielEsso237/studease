import 'package:flutter/material.dart';

class QuestionSuggestions extends StatelessWidget {
  final void Function(String question) onSuggestionTap;

  const QuestionSuggestions({super.key, required this.onSuggestionTap});

  static const List<Map<String, dynamic>> _suggestions = [
    {
      'icon': Icons.payments_outlined,
      'label': 'Quels sont les frais universitaires ?',
    },
    {
      'icon': Icons.how_to_reg_outlined,
      'label': 'Comment faire une préinscription ?',
    },
    {
      'icon': Icons.calendar_month_outlined,
      'label': 'Quel est le calendrier académique ?',
    },
    {
      'icon': Icons.folder_outlined,
      'label': 'Quelles pièces constituer pour le dossier ?',
    },
    {
      'icon': Icons.location_on_outlined,
      'label': 'Où se trouve la faculté sur le campus ?',
    },
    {
      'icon': Icons.meeting_room_outlined,
      'label': 'Quelles sont les salles et amphis disponibles ?',
    },
    {
      'icon': Icons.schedule_outlined,
      'label': 'Quand commencent les cours ce semestre ?',
    },
    {'icon': Icons.info_outline, 'label': 'Comment contacter le secrétariat ?'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text(
            "Questions fréquentes",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final s = _suggestions[index];
              return _SuggestionChip(
                icon: s['icon'] as IconData,
                label: s['label'] as String,
                onTap: () => onSuggestionTap(s['label'] as String),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed ? Colors.blue.shade300 : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 15,
              color: _pressed ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _pressed ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
