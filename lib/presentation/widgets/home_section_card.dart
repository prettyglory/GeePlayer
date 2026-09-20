import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';
import 'package:gee_player/presentation/widgets/media_state_panel.dart';

class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    required this.title,
    required this.message,
    required this.icon,
    this.onOpen,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GeeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GeeColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 14, 0),
            child: Row(
              children: [
                Icon(icon, color: GeeColors.accentLight, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onOpen != null)
                  IconButton(
                    tooltip: 'Open $title',
                    onPressed: onOpen,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
              ],
            ),
          ),
          MediaStatePanel(
            status: MediaViewStatus.empty,
            message: message,
            icon: icon,
            compact: true,
          ),
        ],
      ),
    );
  }
}
