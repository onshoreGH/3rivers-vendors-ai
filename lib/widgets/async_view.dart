import 'package:flutter/material.dart';

import '../core/api/api_exception.dart';
import 'page_body.dart';

/// One consistent treatment for the load / error / empty / data states so
/// every screen behaves the same and Apple review never sees a spinner
/// that never resolves or a raw exception string.
class AsyncView<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Future<void> Function() onRetry;
  final bool Function(T data) isEmpty;
  final Widget Function(T data) builder;
  final Widget emptyState;

  const AsyncView({
    super.key,
    required this.snapshot,
    required this.onRetry,
    required this.builder,
    required this.emptyState,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return PageBody(child: _content(context));
  }

  Widget _content(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final e = snapshot.error;
      final message = e is ApiException
          ? e.message
          : 'Something went wrong. Please try again.';
      return _Message(
        icon: e is ApiException && e.isNetwork
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded,
        title: e is ApiException && e.isNetwork
            ? 'No connection'
            : 'Unable to load',
        detail: message,
        onRetry: onRetry,
      );
    }

    final data = snapshot.data;
    if (data == null || isEmpty(data)) return emptyState;
    return RefreshIndicator(onRefresh: onRetry, child: builder(data));
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function() onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Neutral empty-state placeholder -- distinct from an error, and never
/// says "coming soon".
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView so RefreshIndicator still works over an empty screen.
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
            semanticLabel: title),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(detail!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
