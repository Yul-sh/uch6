import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/form_submit.dart';
import '../models/client.dart';
import '../models/loyalty_card.dart';
import '../repositories/client_repository.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/list_status_views.dart';

class ClientFormScreen extends StatefulWidget {
  final String? id;
  const ClientFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _ready = false;
  bool _dirty = false;
  bool _saving = false;
  bool _emailTaken = false;
  Map<String, String> _serverErrors = {};

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  String _status = 'active';
  DateTime _issuedAt = DateTime.now();
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    for (final c in [_firstName, _lastName, _email, _phone, _cardNumber]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final client = await context.read<ClientRepository>().findById(
        widget.id!,
      );
      if (client != null && mounted) {
        _firstName.text = client.firstName;
        _lastName.text = client.lastName;
        _email.text = client.email;
        _phone.text = client.phone;
        _cardNumber.text = client.card.number;
        _status = client.card.status;
        _issuedAt = client.card.issuedAt;
        _expiresAt = client.card.expiresAt;
      }
    }
    if (mounted) {
      setState(() {
        _ready = true;
        _dirty = false;
      });
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _serverErrors = {};
    _emailTaken = false;
    if (!_formKey.currentState!.validate()) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    final client = Client(
      id: widget.id ?? '',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim().toLowerCase(),
      phone: _phone.text.trim(),
      card: LoyaltyCard(
        number: _cardNumber.text.trim(),
        issuedAt: _issuedAt,
        expiresAt:
            _expiresAt ?? DateTime.now().add(const Duration(days: 365 * 3)),
        status: _status,
      ),
    );
    final repo = context.read<ClientRepository>();
    final ok = await runApiSave(
      context: context,
      action: () async {
        widget.isEditing
            ? await repo.update(client)
            : await repo.create(client);
      },
      onValidation: (errors) {
        _serverErrors = errors;
        _emailTaken = errors['email'] != null;
        _formKey.currentState?.validate();
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    context.go('/clients');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: LoadingView());
    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование клиента' : 'Новый клиент',
      saveLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      leavePath: '/clients',
      dirty: _dirty,
      loading: _saving,
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.personName(v, label: 'Фамилия'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: (v) => Validators.personName(v, label: 'Имя'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'Почта',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final base = Validators.email(value);
            if (base != null) return base;
            if (_serverErrors['email'] != null) return _serverErrors['email'];
            if (_emailTaken) return 'Такая почта уже зарегистрирована';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
          ),
          validator: Validators.phone,
        ),
        const SizedBox(height: 20),
        Text(
          'Карта лояльности',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumber,
          decoration: const InputDecoration(
            labelText: 'Номер карты',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final required = Validators.requiredField(v, label: 'номер карты');
            if (required != null) return required;
            return Validators.minLength(v, 4, label: 'Номер карты');
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(
            labelText: 'Статус карты',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Активна')),
            DropdownMenuItem(value: 'expired', child: Text('Истекла')),
          ],
          onChanged: (value) {
            setState(() {
              _status = value ?? 'active';
              _dirty = true;
            });
          },
          validator: (v) => v == null ? 'Выберите статус' : null,
        ),
      ],
    );
  }
}
