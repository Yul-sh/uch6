import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/api_error_dialog.dart';
import '../widgets/list_status_views.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final user = context.read<AuthNotifier>().user;
      if (user == null) {
        if (mounted) setState(() => _items = []);
        return;
      }
      final items = await context.read<BookingRepository>().mine(user.id);
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = '${e.message}\n\n${e.kindLabel}');
    }
  }

  Future<void> _extend(Booking item) async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.dialogMaxWidth,
          ),
          child: AlertDialog(
            alignment: Alignment.center,
            title: const Text('На сколько продлить?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Сейчас: ${item.subtitleRu}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                for (final option in const [
                  (1, '1 день'),
                  (7, '7 дней'),
                  (14, '14 дней'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.pop(ctx, option.$1),
                        child: Text(option.$2),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
    if (days == null || !mounted) return;
    try {
      await context.read<BookingRepository>().extend(item.id, days: days);
      await _load();
    } on ApiException catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои брони')),
      body: _error != null
          ? ErrorResultView(message: _error!, onRetry: _load)
          : _items == null
          ? const LoadingView()
          : _items!.isEmpty
          ? const EmptyResultView(message: 'У вас пока нет броней')
          : ListView(
              children: [
                for (final item in _items!)
                  ListTile(
                    title: Text(
                      item.tourTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.subtitleRu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.isActive
                        ? TextButton(
                            onPressed: () => _extend(item),
                            child: const Text('Продлить'),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}
