import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class TutorialStep {
  final String title;
  final String message;
  final GlobalKey? targetKey;
  final Alignment alignment;

  TutorialStep({
    required this.title,
    required this.message,
    this.targetKey,
    this.alignment = Alignment.center,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onCompleted;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStepIndex = 0;

  void _nextStep() {
    setState(() {
      if (_currentStepIndex < widget.steps.length - 1) {
        _currentStepIndex++;
      } else {
        widget.onCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[_currentStepIndex];
    
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        children: [
          // Target Highlight (if key provided)
          if (currentStep.targetKey != null)
            _Highlighter(targetKey: currentStep.targetKey!),

          // Tutorial Card
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: currentStep.alignment == Alignment.center 
                      ? MainAxisAlignment.center 
                      : currentStep.alignment == Alignment.bottomCenter
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lightbulb, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentStep.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onSkip,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentStep.message,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondaryColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_currentStepIndex + 1} of ${widget.steps.length}',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  _currentStepIndex < widget.steps.length - 1 ? 'Next' : 'Got it!',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlighter extends StatelessWidget {
  final GlobalKey targetKey;

  const _Highlighter({required this.targetKey});

  @override
  Widget build(BuildContext context) {
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: offset.dx - 8,
                top: offset.dy - 8,
                child: Container(
                  width: size.width + 16,
                  height: size.height + 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
