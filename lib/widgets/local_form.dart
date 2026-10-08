import 'package:flutter/material.dart';

import '../models/local.dart';
import '../services/local_service.dart';

Future<void> showLocalForm(
  BuildContext context,
  LocalService service, {
  Local? local,
  String cidade = 'São Paulo',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF9FAF9),
    builder: (context) =>
        _LocalForm(service: service, local: local, cidade: cidade),
  );
}

class _LocalForm extends StatefulWidget {
  const _LocalForm({
    required this.service,
    required this.local,
    required this.cidade,
  });

  final LocalService service;
  final Local? local;
  final String cidade;

  @override
  State<_LocalForm> createState() => _LocalFormState();
}

class _LocalFormState extends State<_LocalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _endereco;
  late final TextEditingController _descricao;
  late final TextEditingController _horario;
  late final TextEditingController _telefone;
  late final TextEditingController _avaliacao;
  late final TextEditingController _distancia;
  late final TextEditingController _fotos;
  late String _cidade;
  late String _categoria;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final local = widget.local;
    _nome = TextEditingController(text: local?.nome ?? '');
    _endereco = TextEditingController(text: local?.endereco ?? '');
    _descricao = TextEditingController(text: local?.descricao ?? '');
    _horario = TextEditingController(text: local?.horario ?? '08:00 - 22:00');
    _telefone = TextEditingController(text: local?.telefone ?? '');
    _avaliacao = TextEditingController(
      text: local?.avaliacao.toString() ?? '0',
    );
    _distancia = TextEditingController(
      text: local?.distancia.toString() ?? '0',
    );
    _fotos = TextEditingController(text: local?.fotos.join('\n') ?? '');
    _cidade = local?.cidade ?? widget.cidade;
    _categoria = local?.categoria ?? 'Academia';
  }

  @override
  void dispose() {
    for (final controller in [
      _nome,
      _endereco,
      _descricao,
      _horario,
      _telefone,
      _avaliacao,
      _distancia,
      _fotos,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;

  String? _number(String? value, {double? max}) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (max != null && number > max)) {
      return max == null
          ? 'Informe um número maior ou igual a zero.'
          : 'Informe uma nota de 0 a 5.';
    }
    return null;
  }

  List<String> get _photoUrls => _fotos.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final previous = widget.local;
    final local = Local(
      id: previous?.id ?? '',
      nome: _nome.text.trim(),
      categoria: _categoria,
      cidade: _cidade,
      avaliacao: double.parse(_avaliacao.text.trim().replaceAll(',', '.')),
      distancia: double.parse(_distancia.text.trim().replaceAll(',', '.')),
      horario: _horario.text.trim(),
      descricao: _descricao.text.trim(),
      favorito: previous?.favorito ?? false,
      endereco: _endereco.text.trim(),
      telefone: _telefone.text.trim(),
      fotos: _photoUrls,
      totalAvaliacoes: previous?.totalAvaliacoes ?? 0,
      mapX: previous?.mapX ?? .5,
      mapY: previous?.mapY ?? .5,
    );
    try {
      if (previous == null) {
        await widget.service.add(local);
      } else {
        await widget.service.update(local);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Não foi possível salvar. Confira a conexão e as permissões do Firestore e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = {'São Paulo', 'Campinas', 'Jundiai', _cidade}.toList();
    final categories = {
      'Academia',
      'Restaurante',
      'Hospital',
      'Café',
      'Parque',
      'Livraria',
      'Mercado',
      _categoria,
    }.toList();
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.local == null
                            ? 'Cadastrar local'
                            : 'Editar local',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_nome, 'Nome', validator: _required),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _categoria = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _cidade,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                  items: cities
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _cidade = value!),
                ),
                const SizedBox(height: 12),
                _field(_endereco, 'Endereço', validator: _required),
                _field(
                  _horario,
                  'Horário de funcionamento',
                  validator: _required,
                ),
                _field(
                  _telefone,
                  'Telefone (opcional)',
                  keyboard: TextInputType.phone,
                ),
                _field(_descricao, 'Descrição', maxLines: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        _avaliacao,
                        'Avaliação (0 a 5)',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _number(value, max: 5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _distancia,
                        'Distância (km)',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _number,
                      ),
                    ),
                  ],
                ),
                _field(
                  _fotos,
                  'Links das fotos (opcional)',
                  maxLines: 2,
                  helper: 'Um link por linha.',
                  validator: (_) {
                    for (final value in _photoUrls) {
                      final uri = Uri.tryParse(value);
                      if (uri == null ||
                          !['https', 'http'].contains(uri.scheme) ||
                          uri.host.isEmpty) {
                        return 'Informe links válidos começando com https://.';
                      }
                    }
                    return null;
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(_saving ? 'Salvando...' : 'Salvar local'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        decoration: InputDecoration(labelText: label, helperText: helper),
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
