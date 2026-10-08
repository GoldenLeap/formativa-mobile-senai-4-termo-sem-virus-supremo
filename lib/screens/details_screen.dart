import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dialogs/confirm_delete.dart';
import '../models/local.dart';
import '../services/local_service.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/local_form.dart';
import '../widgets/local_image.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.service, required this.local});

  final LocalService service;
  final Local local;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Stream<Local?> _localStream;
  bool _busy = false;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _localStream = widget.service.observarLocal(widget.local.id);
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _favorite(Local local) async {
    setState(() => _busy = true);
    try {
      await widget.service.favorite(local.id, !local.favorito);
    } catch (_) {
      _notify('Não foi possível atualizar o favorito. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Local local) async {
    if (!await confirmDelete(context, local) || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.service.delete(local.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _notify('Não foi possível excluir o local. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String value, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      _notify(message);
    } catch (_) {
      _notify('Não foi possível copiar.');
    }
  }

  Future<void> _contact(Local local, {bool address = false}) async {
    final value = address ? local.endereco : local.telefone;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(address ? 'Como chegar' : 'Telefone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              value.isNotEmpty
                  ? value
                  : (address
                        ? 'Endereço não cadastrado.'
                        : 'Telefone não cadastrado.'),
            ),
            if (address && value.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Copie o endereço para consultar a rota no seu aplicativo de mapas.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          if (value.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _copy(
                  value,
                  address ? 'Endereço copiado.' : 'Telefone copiado.',
                );
              },
              child: const Text('Copiar'),
            ),
        ],
      ),
    );
  }

  Future<void> _planVisit(Local local) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Planejar visita',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted || time == null) return;
    final day =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Visita planejada'),
        content: Text(
          '${local.nome}\n$day às ${time.format(context)}.\n\n'
          'Para confirmar um agendamento, entre em contato com o local. Esta seleção não realiza uma reserva e não fica salva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _gallery(Local local, [int initialIndex = 0]) {
    if (local.fotos.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          height: 440,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Fotos de ${local.nome}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar fotos',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _PhotoGallery(
                  urls: local.fotos,
                  initialIndex: initialIndex,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Deslize para ver as fotos.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Local?>(
      stream: _localStream,
      initialData: widget.local,
      builder: (context, snapshot) {
        final local = snapshot.data;
        final available = !snapshot.hasError && local != null;
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAF9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAF9),
            elevation: 0,
            leading: IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.chevron_left),
              onPressed: _busy ? null : () => Navigator.pop(context),
            ),
            actions: local != null && !snapshot.hasError
                ? [
                    IconButton(
                      tooltip: local.favorito
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                      onPressed: _busy ? null : () => _favorite(local),
                      icon: Icon(
                        local.favorito ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copiar informações do local',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _copy(
                        '${local.nome}\n${local.endereco}\n${local.cidade}',
                        'Informações do local copiadas.',
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Gerenciar local',
                      enabled: !_busy,
                      onSelected: (value) {
                        if (value == 'edit') {
                          showLocalForm(context, widget.service, local: local);
                        } else {
                          _delete(local);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar local'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir local'),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          body: snapshot.hasError
              ? _message(
                  Icons.cloud_off_outlined,
                  'Não foi possível ler este local.',
                  'Confira a conexão e as permissões do Firestore.',
                  retry: () => setState(
                    () => _localStream = widget.service.observarLocal(
                      widget.local.id,
                    ),
                  ),
                )
              : local == null
              ? snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : _message(
                        Icons.location_off_outlined,
                        'Local não encontrado.',
                        'Ele pode ter sido excluído.',
                      )
              : _content(
                  local,
                  snapshot.connectionState == ConnectionState.waiting,
                ),
          bottomNavigationBar: AppBottomBar(
            currentIndex: 0,
            onTap: _busy
                ? (_) {}
                : (index) {
                    if (index == 0 && available) {
                      Navigator.pop(context, local);
                    } else if (index == 1) {
                      Navigator.pop(context, 1);
                    } else if (index == 2) {
                      Navigator.pop(context, 2);
                    }
                  },
          ),
        );
      },
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String description, {
    VoidCallback? retry,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: const Color(0xFF858C89)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
              if (retry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: retry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Local local, bool loading) {
    const muted = Color(0xFF777D7A);
    final count = local.fotos.isEmpty ? 1 : local.fotos.length;
    return Column(
      children: [
        if (loading || _busy) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 2.3,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: count,
                          onPageChanged: (index) =>
                              setState(() => _photoIndex = index),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: local.fotos.isEmpty
                                ? null
                                : () => _gallery(local, index),
                            child: LocalImage(
                              url: local.fotos.isEmpty
                                  ? null
                                  : local.fotos[index],
                            ),
                          ),
                        ),
                        if (local.fotos.isNotEmpty)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF929794),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                child: Text(
                                  '${(_photoIndex + 1).clamp(1, count)}/$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      count,
                      (index) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _photoIndex
                              ? const Color(0xFF353B3D)
                              : const Color(0xFFCFD3D0),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  local.nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF353B3D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  local.categoria,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      local.avaliacao.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${local.totalAvaliacoes} avaliações)',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _information(
                      Icons.location_on_outlined,
                      '${local.distancia.toStringAsFixed(1).replaceAll('.', ',')} km',
                    ),
                    _information(
                      Icons.access_time,
                      local.horario.isEmpty
                          ? 'Horário não informado'
                          : local.horario,
                    ),
                  ],
                ),
                if (local.endereco.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${local.endereco} · ${local.cidade}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    _action(
                      'Ligar',
                      Icons.call_outlined,
                      () => _contact(local),
                    ),
                    _action(
                      'Como chegar',
                      Icons.near_me_outlined,
                      () => _contact(local, address: true),
                    ),
                    _action(
                      'Agendar',
                      Icons.calendar_month_outlined,
                      () => _planVisit(local),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                const Text(
                  'Sobre',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  local.descricao.isEmpty
                      ? 'Descrição não cadastrada.'
                      : local.descricao,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Fotos',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: local.fotos.isEmpty
                          ? null
                          : () => _gallery(local),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Ver todas ›',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(3, (index) {
                    final exists = index < local.fotos.length;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                        child: GestureDetector(
                          onTap: exists ? () => _gallery(local, index) : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: AspectRatio(
                              aspectRatio: 1.75,
                              child: LocalImage(
                                url: exists ? local.fotos[index] : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => Navigator.pop(context, local),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF353B3D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.location_on, size: 18),
              label: const Text('Ver no mapa'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _information(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF777D7A)),
        ),
      ],
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDEE2DF)),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF777D7A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.urls.length,
      itemBuilder: (context, index) =>
          LocalImage(url: widget.urls[index], fit: BoxFit.contain),
    );
  }
}
