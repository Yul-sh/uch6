import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/form_submit.dart';
import '../widgets/api_error_dialog.dart';
import '../widgets/can.dart';
import '../models/role.dart';
import '../repositories/booking_repository.dart';
import '../state/auth_notifier.dart';
import '../state/catalog_lookups.dart';
import '../state/load_status.dart';
import '../state/tour_detail_notifier.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/entity_detail_card.dart';
import '../widgets/list_status_views.dart';

class TourDetailScreen extends StatelessWidget {
  const TourDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TourDetailNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка тура'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tours');
            }
          },
        ),
        actions: [
          if (context.watch<AuthNotifier>().can(AppOp.manageCatalog))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/tours/${notifier.id}/edit'),
            ),
        ],
      ),
      body: switch (notifier.status) {
        LoadStatus.idle || LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorResultView(
          message: notifier.error ?? 'Тур не найден',
          onRetry: notifier.load,
        ),
        LoadStatus.success => _TourCard(notifier: notifier),
      },
    );
  }
}

class _TourCard extends StatelessWidget {
  final TourDetailNotifier notifier;

  const _TourCard({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<CatalogLookups>();
    if (lookups.destinations.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<CatalogLookups>().ensureLoaded();
      });
    }
    final tour = notifier.tour!;
    final rows = <(String, String)>[
      ('Название', tour.title),
      ('Код', tour.code),
      ('Год', '${tour.year}'),
      ('Длительность', '${tour.durationDays} дней'),
      ('Направление', lookups.destinationName(
        tour.destinationId,
        fallback: tour.destinationLabel,
      )),
      ('Тип', lookups.categoryNames(
        tour.categoryIds,
        fallback: tour.categoriesLabel,
      )),
      ('Отели', lookups.hotelNames(
        tour.hotelIds,
        fallback: tour.hotelsLabel,
      )),
      ('Мест', '${tour.seatsAvailable} из ${tour.seatsTotal}'),
      ('Цена', '${tour.price} ₽'),
      ('Статус', tour.isDeleted ? 'Скрыт' : 'В каталоге'),
    ];

    return EntityDetailCard(
      rows: rows,
      actions: [
        if (tour.isDeleted)
          Can(
            op: AppOp.restore,
            child: FilledButton.icon(
              onPressed: notifier.restore,
              icon: const Icon(Icons.restore),
              label: const Text('Восстановить'),
            ),
          )
        else ...[
          Can(
            op: AppOp.issueBooking,
            child: FilledButton.icon(
              onPressed: () async {
                final auth = context.read<AuthNotifier>();
                final bookings = context.read<BookingRepository>();
                try {
                  final user = auth.user;
                  if (user == null) {
                    throw const UnauthorizedException();
                  }
                  // Сначала бронь (клиент может создавать), потом места.
                  await bookings.create(
                    tourId: notifier.id,
                    userId: user.id,
                    tourTitle: notifier.tour?.title ?? '',
                  );
                  await notifier.book();
                  if (context.mounted) {
                    showApiMessage(context, 'Место забронировано.');
                  }
                } on ApiException catch (e) {
                  if (context.mounted) showApiError(context, e);
                }
              },
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Забронировать'),
            ),
          ),
          Can(
            op: AppOp.softDelete,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Скрыть тур',
                  message: 'Тур будет скрыт из каталога.',
                  confirmLabel: 'Скрыть',
                );
                if (ok) await notifier.softDelete();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Скрыть'),
            ),
          ),
        ],
        Can(
          op: AppOp.hardDelete,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Удалить навсегда',
                message: 'Запись будет стёрта из памяти.',
                confirmLabel: 'Удалить навсегда',
              );
              if (ok && context.mounted) {
                try {
                  await notifier.hardDelete();
                  if (context.mounted) context.go('/tours');
                } on ApiException catch (e) {
                  if (context.mounted) await showApiError(context, e);
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Удалить навсегда'),
          ),
        ),
      ],
    );
  }
}
