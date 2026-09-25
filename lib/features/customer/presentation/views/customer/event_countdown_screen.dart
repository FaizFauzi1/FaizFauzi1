import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen animated event countdown.
/// Displays days / hours / minutes / seconds remaining until [event.startTime].
class EventCountdownScreen extends StatefulWidget {
  final Event event;

  const EventCountdownScreen({super.key, required this.event});

  @override
  State<EventCountdownScreen> createState() => _EventCountdownScreenState();
}

class _EventCountdownScreenState extends State<EventCountdownScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _hasEnded = false;

  // Animation controllers for the pulse effect on each tile
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });

    // Keep the status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final target = widget.event.startTime;
    final diff = target.difference(now);
    if (!mounted) return;
    if (diff.isNegative) {
      setState(() {
        _remaining = Duration.zero;
        _hasEnded = true;
      });
      _timer?.cancel();
    } else {
      setState(() {
        _remaining = diff;
        _hasEnded = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  // ────────────────────────────────────────────────
  // Colour palette derived from event type
  // ────────────────────────────────────────────────
  List<Color> get _gradientColors {
    final type = widget.event.type.id.toLowerCase();
    if (type.contains('wedding')) {
      return [const Color(0xFF6B3FA0), const Color(0xFFD4A5FF)];
    } else if (type.contains('birthday')) {
      return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
    } else if (type.contains('corporate') || type.contains('conference')) {
      return [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
    } else if (type.contains('concert') || type.contains('music')) {
      return [const Color(0xFF0F3460), const Color(0xFFE94560)];
    } else {
      return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
    }
  }

  Color get _accentColor {
    return _gradientColors.length > 1 ? _gradientColors[1] : Colors.white;
  }

  // ────────────────────────────────────────────────
  // Share countdown text
  // ────────────────────────────────────────────────
  void _shareCountdown() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final event = widget.event;
    final text =
        '⏳ Counting down to ${event.title}!\n'
        '$days days, $hours hours, $minutes minutes to go!\n'
        '📅 ${event.date.day}/${event.date.month}/${event.date.year} '
        'at ${event.venue.name}\n\n'
        'Powered by EventEase 🎉';
    Share.share(text, subject: 'Countdown to ${event.title}');
  }

  // ────────────────────────────────────────────────
  // Widget setup info sheet
  // ────────────────────────────────────────────────
  void _showWidgetSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WidgetSetupSheet(eventTitle: widget.event.title),
    );
  }

  // ────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareCountdown,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 8),

              // ── Event name & icon ──
              _buildHeader(event),

              // ── Countdown tiles ──
              if (_hasEnded)
                _buildEndedWidget()
              else
                _buildCountdownTiles(days, hours, minutes, seconds),

              // ── Event info card ──
              _buildEventInfo(event),

              // ── Action buttons ──
              _buildActions(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              event.type.displayName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTiles(int days, int hours, int minutes, int seconds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CountdownTile(value: days, label: 'Days', accentColor: _accentColor),
          _Separator(),
          _CountdownTile(value: hours, label: 'Hours', accentColor: _accentColor),
          _Separator(),
          _CountdownTile(value: minutes, label: 'Mins', accentColor: _accentColor),
          _Separator(),
          _CountdownTile(value: seconds, label: 'Secs', accentColor: _accentColor),
        ],
      ),
    );
  }

  Widget _buildEndedWidget() {
    return Column(
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
        const SizedBox(height: 16),
        const Text(
          'The Event Has Started!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hope you\'re having a wonderful time! 🎉',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEventInfo(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            text:
                '${event.date.day}/${event.date.month}/${event.date.year}  •  '
                '${event.startTime.hour.toString().padLeft(2, '0')}:'
                '${event.startTime.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on_rounded,
            text: event.venue.name,
          ),
          if (event.theme != null && event.theme!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.palette_rounded, text: 'Theme: ${event.theme}'),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: _shareCountdown,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.widgets_rounded,
              label: 'Add Widget',
              onTap: _showWidgetSetupSheet,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Sub-widgets
// ────────────────────────────────────────────────────────────

class _CountdownTile extends StatelessWidget {
  final int value;
  final String label;
  final Color accentColor;

  const _CountdownTile({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Container(
            key: ValueKey(value),
            width: 72,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Widget Setup Bottom Sheet
// ────────────────────────────────────────────────────────────

class _WidgetSetupSheet extends StatelessWidget {
  final String eventTitle;

  const _WidgetSetupSheet({required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B3FA0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.widgets_rounded, color: Color(0xFFD4A5FF)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Home Screen Widget',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'See the countdown right on your screen',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Steps
            _StepItem(
              step: '1',
              title: 'Go to your home screen',
              subtitle: 'Long-press on an empty area of your home screen',
            ),
            _StepItem(
              step: '2',
              title: 'Tap "Widgets"',
              subtitle: 'Find the Widgets button that appears at the bottom or in the menu',
            ),
            _StepItem(
              step: '3',
              title: 'Find EventEase',
              subtitle: 'Scroll to "EventEase" in the widget list',
            ),
            _StepItem(
              step: '4',
              title: 'Add Event Countdown widget',
              subtitle: 'Drag the "Event Countdown" widget to your home screen',
            ),
            _StepItem(
              step: '5',
              title: 'Your event is synced automatically',
              subtitle: 'The widget will display: "$eventTitle"',
              isLast: true,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B3FA0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final bool isLast;

  const _StepItem({
    required this.step,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B3FA0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: const Color(0xFF6B3FA0).withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
