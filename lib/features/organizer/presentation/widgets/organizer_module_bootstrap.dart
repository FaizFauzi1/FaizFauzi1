import 'package:flutter/material.dart';
import 'package:eventease/features/organizer/data/organizer_data_mode.dart';

/// Loads persisted demo/live mode before the first organizer route builds.
class OrganizerModuleBootstrap extends StatefulWidget {
  const OrganizerModuleBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<OrganizerModuleBootstrap> createState() => _OrganizerModuleBootstrapState();
}

class _OrganizerModuleBootstrapState extends State<OrganizerModuleBootstrap> {
  @override
  void initState() {
    super.initState();
    OrganizerDataModeController.instance.load();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Wraps organizer route builders so data mode is ready on first paint.
Widget wrapOrganizerRoute(Widget child) => OrganizerModuleBootstrap(child: child);
