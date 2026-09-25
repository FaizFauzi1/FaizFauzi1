import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/organizer_data_mode.dart';

/// Loads async organizer data; reloads when demo/live mode changes.
class OrganizerAsyncBody<T> extends StatefulWidget {
  final Future<T> Function()? loader;
  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry padding;

  const OrganizerAsyncBody({
    super.key,
    this.loader,
    this.future,
    required this.builder,
    this.isEmpty,
    this.emptyWidget,
    this.padding = const EdgeInsets.all(24),
  }) : assert(loader != null || future != null, 'Provide loader or future');

  @override
  State<OrganizerAsyncBody<T>> createState() => _OrganizerAsyncBodyState<T>();
}

class _OrganizerAsyncBodyState<T> extends State<OrganizerAsyncBody<T>> {
  late Future<T> _future;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _future = _resolveFuture();
    OrganizerDataModeController.instance.addListener(_onModeChanged);
  }

  @override
  void didUpdateWidget(covariant OrganizerAsyncBody<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader || oldWidget.future != widget.future) {
      setState(() => _future = _resolveFuture());
    }
  }

  @override
  void dispose() {
    OrganizerDataModeController.instance.removeListener(_onModeChanged);
    super.dispose();
  }

  Future<T> _resolveFuture() {
    _generation++;
    final fut = (widget.loader?.call() ?? widget.future)!;
    // Print any load error to the terminal for ALL organizer screens.
    return fut.catchError((Object e, StackTrace st) {
      debugPrint('[OrganizerScreen] Load failed: $e\n$st');
      throw e;
    });
  }

  void _onModeChanged() {
    setState(() => _future = _resolveFuture());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: ValueKey(_generation),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: widget.padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppTheme.textSecondaryColor),
                const SizedBox(height: 12),
                Text(
                  'Could not load data',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final data = snapshot.data;
        if (data == null || (widget.isEmpty != null && widget.isEmpty!(data))) {
          return widget.emptyWidget ??
              Center(
                child: Padding(
                  padding: widget.padding,
                  child: Text(
                    'No data yet',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              );
        }
        return widget.builder(context, data);
      },
    );
  }
}
