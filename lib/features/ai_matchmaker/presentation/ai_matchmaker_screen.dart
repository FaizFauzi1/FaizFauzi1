import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/shared/widgets/design_system/premium_widgets.dart';

/// AI-style vendor matchmaker quiz flow.
class AiMatchmakerScreen extends StatefulWidget {
  const AiMatchmakerScreen({super.key});

  @override
  State<AiMatchmakerScreen> createState() => _AiMatchmakerScreenState();
}

class _AiMatchmakerScreenState extends State<AiMatchmakerScreen> {
  int _step = 0;
  String? _eventType;
  String? _budget;
  String? _style;

  final _steps = ['Event Type', 'Budget', 'Style', 'Results'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Matchmaker')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / _steps.length),
          Padding(
            padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
            child: Text(_steps[_step], style: EEDesignTokens.headlineMedium),
          ),
          Expanded(child: _buildStep()),
          Padding(
            padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _canContinue
                      ? () => setState(() {
                            if (_step < _steps.length - 1) _step++;
                          })
                      : null,
                  child: Text(_step == _steps.length - 1 ? 'Done' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _eventType != null;
      case 1:
        return _budget != null;
      case 2:
        return _style != null;
      default:
        return true;
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _optionGrid(['Wedding', 'Corporate', 'Birthday', 'Other'], _eventType, (v) => _eventType = v);
      case 1:
        return _optionGrid(['< RM 10k', 'RM 10–30k', 'RM 30–80k', 'RM 80k+'], _budget, (v) => _budget = v);
      case 2:
        return _optionGrid(['Classic', 'Modern', 'Rustic', 'Luxury'], _style, (v) => _style = v);
      default:
        return ListView(
          padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
          children: [
            const Text('Recommended vendors based on your preferences:'),
            const SizedBox(height: 16),
            _matchCard('Studio Lumina', 0.94),
            _matchCard('Garden Events Co.', 0.89),
            _matchCard('Elite Catering', 0.85),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Inquire All Matches'),
            ),
          ],
        );
    }
  }

  Widget _optionGrid(List<String> options, String? selected, ValueChanged<String> onSelect) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return FilterChipPill(
          label: opt,
          selected: isSelected,
          onTap: () => setState(() => onSelect(opt)),
        );
      }).toList(),
    );
  }

  Widget _matchCard(String name, double score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name),
        subtitle: PillBadge(label: '${(score * 100).round()}% match'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
