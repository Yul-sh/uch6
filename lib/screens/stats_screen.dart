import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../repositories/admin_repository.dart';
import '../widgets/api_error_dialog.dart';
import '../widgets/list_status_views.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await context.read<AdminRepository>().stats();
      if (mounted) setState(() => _stats = stats);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = '${e.message}\n\n${e.kindLabel}');
        await showApiError(context, e);
      }
    }
  }

  static const _labels = {
    'users': 'Пользователи',
    'tours': 'Туры',
    'hotels': 'Отели',
    'clients': 'Клиенты',
    'bookings': 'Брони',
    'activeBookings': 'Активные брони',
  };

  String _label(String key) => _labels[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: _error != null && _stats == null
          ? ErrorResultView(message: _error!, onRetry: _load)
          : _stats == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in _stats!.entries)
                  Card(
                    child: ListTile(
                      title: Text(_label(entry.key)),
                      trailing: Text(
                        '${entry.value}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
