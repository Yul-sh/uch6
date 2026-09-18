import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../repositories/client_repository.dart';
import '../repositories/lookup_repositories.dart';
import '../widgets/entity_detail_card.dart';
import '../widgets/list_status_views.dart';

class _InfoPage extends StatelessWidget {
  final String title;
  final String back;
  final String edit;
  final List<(String, String)> rows;

  const _InfoPage({
    required this.title,
    required this.back,
    required this.edit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(back),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go(edit),
          ),
        ],
      ),
      body: EntityDetailCard(rows: rows),
    );
  }
}

class DestinationDetailScreen extends StatelessWidget {
  final String id;
  const DestinationDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<DestinationRepository>().findById(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: LoadingView());
        final item = snapshot.data;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Не найдено')));
        }
        return _InfoPage(
          title: 'Направление',
          back: '/destinations',
          edit: '/destinations/$id/edit',
          rows: [
            ('Название', item.name),
            ('Страна', item.country),
            ('Статус', item.isDeleted ? 'Скрыто' : 'В каталоге'),
          ],
        );
      },
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String id;
  const CategoryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CategoryRepository>().findById(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: LoadingView());
        final item = snapshot.data;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Не найдено')));
        }
        return _InfoPage(
          title: 'Тип тура',
          back: '/categories',
          edit: '/categories/$id/edit',
          rows: [
            ('Название', item.name),
            ('Статус', item.isDeleted ? 'Скрыт' : 'В каталоге'),
          ],
        );
      },
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  final String id;
  const ClientDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<ClientRepository>().findById(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: LoadingView());
        final Client? item = snapshot.data;
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Не найдено')));
        }
        return _InfoPage(
          title: 'Клиент',
          back: '/clients',
          edit: '/clients/$id/edit',
          rows: [
            ('Фамилия', item.lastName),
            ('Имя', item.firstName),
            ('Почта', item.email),
            ('Телефон', item.phone),
            ('Карта', item.card.number),
            (
              'Статус карты',
              item.card.status == 'active' ? 'Активна' : 'Истекла',
            ),
          ],
        );
      },
    );
  }
}
