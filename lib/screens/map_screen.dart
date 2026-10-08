import 'package:flutter/material.dart';

import '../models/local.dart';
import '../services/local_service.dart';
import '../utils/search.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/local_form.dart';
import '../widgets/map_background.dart';
import 'details_screen.dart';
import 'results_screen.dart';

const _ink = Color(0xFF353B3D);
const _muted = Color(0xFF858C89);
const _surface = Color(0xFFF9FAF9);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.service});
  final LocalService? service;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _searchController = TextEditingController();
  final _mapController = TransformationController();
  late final LocalService _service;
  late Stream<List<Local>> _stream;
  String _city = 'São Paulo';
  String _query = '';
  String? _selectedId;
  int _tab = 0;
  bool _showParks = true;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LocalService();
    _stream = _service.listarLocais();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _acceptNavigation(Object? result) {
    if (!mounted) return;
    if (result is Local) {
      setState(() {
        _tab = 0;
        _city = result.cidade;
        _query = '';
        _searchController.clear();
        _selectedId = result.id;
      });
      _mapController.value = Matrix4.identity();
    } else if (result is int) {
      _navigate(result);
    }
  }

  Future<void> _openResults({bool favorites = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          service: _service,
          cidade: _city,
          query: favorites ? '' : _query,
          favoritos: favorites,
        ),
      ),
    );
    _acceptNavigation(result);
  }

  Future<void> _openDetails(Local local) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedId = local.id);
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(service: _service, local: local),
      ),
    );
    _acceptNavigation(result);
  }

  void _navigate(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index == 1) {
      _openResults(favorites: true);
    } else {
      setState(() => _tab = index);
    }
  }

  Future<void> _chooseCity(List<Local> locals) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final cities = {
      'São Paulo',
      'Campinas',
      'Jundiai',
      ...locals.map((local) => local.cidade),
    }.where((city) => city.isNotEmpty).toList();
    final city = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetTitle('Selecionar cidade'),
              for (final city in cities)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(city),
                  trailing: city == _city ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, city),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
    if (!mounted || city == null || city == _city) return;
    setState(() {
      _city = city;
      _query = '';
      _searchController.clear();
      _selectedId = null;
    });
    _mapController.value = Matrix4.identity();
  }

  Future<void> _chooseLayers() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final parks = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetTitle('Camadas do mapa'),
            for (final option in [(true, 'Mapa claro'), (false, 'Apenas ruas')])
              ListTile(
                leading: Icon(
                  option.$1 ? Icons.layers_outlined : Icons.map_outlined,
                ),
                title: Text(option.$2),
                trailing: option.$1 == _showParks
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, option.$1),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (mounted && parks != null) setState(() => _showParks = parks);
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await _service.seedDefaults();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Locais de exemplo adicionados ao Firestore.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível cadastrar os exemplos. Verifique a conexão e as permissões do Firestore.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Local>>(
      stream: _stream,
      builder: (context, snapshot) {
        final locals = snapshot.data ?? <Local>[];
        final visible = locals
            .where(
              (local) => local.cidade == _city && matchesLocal(local, _query),
            )
            .toList();
        return Scaffold(
          backgroundColor: _surface,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(locals),
                Expanded(
                  child: _tab == 2
                      ? _buildProfile(locals)
                      : snapshot.hasError
                      ? _buildError()
                      : snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMap(visible),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomBar(
            currentIndex: _tab,
            onTap: _navigate,
          ),
        );
      },
    );
  }

  Widget _buildHeader(List<Local> locals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => _chooseCity(locals),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: _ink, size: 28),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cidade selecionada',
                          style: TextStyle(fontSize: 11, color: _ink),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _city,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver resultados',
                    onPressed: () => _openResults(),
                    icon: const Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_tab == 0) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => _openResults(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13, color: _ink),
              decoration: InputDecoration(
                hintText: 'Buscar locais, endereços ou categorias...',
                hintStyle: const TextStyle(color: _muted, fontSize: 12),
                prefixIcon: IconButton(
                  tooltip: 'Pesquisar',
                  onPressed: () => _openResults(),
                  icon: const Icon(Icons.search, color: _ink, size: 22),
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close, size: 19),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: const Color(0xFFF7F8F7),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFCCD1CE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFCCD1CE)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 38, color: _muted),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar os locais',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique a conexão e as permissões do Firestore.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() => _stream = _service.listarLocais()),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );

  Widget _buildMap(List<Local> locals) {
    final selected = locals.any((local) => local.id == _selectedId)
        ? _selectedId
        : locals.firstOrNull?.id;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();
        return ClipRect(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _mapController,
                minScale: 1,
                maxScale: 3,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MapBackground(showParks: _showParks),
                      ),
                      Positioned(
                        left: width * .5 - 25,
                        top: height * .39 - 25,
                        child: Semantics(
                          label: 'Ponto de referência ilustrativo',
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF529CF2)
                                  .withValues(alpha: .14),
                            ),
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF498FED),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (final local in locals)
                        Positioned(
                          left: width * local.mapX.clamp(.08, .90) - 24,
                          top: height * local.mapY.clamp(.08, .90) - 32,
                          child: Tooltip(
                            message: local.nome,
                            child: Semantics(
                              button: true,
                              label: 'Ver ${local.nome}',
                              child: InkWell(
                                onTap: () => _openDetails(local),
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 48,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: local.id == selected
                                        ? Container(
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  width *
                                                      (1 -
                                                          local.mapX.clamp(
                                                            .08,
                                                            .90,
                                                          )) +
                                                  16,
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                              4,
                                              4,
                                              10,
                                              4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _surface,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              border: Border.all(
                                                color: const Color(0xFFDDE1DE),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 27,
                                                  color: Color(0xFF585E5D),
                                                ),
                                                const SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    local.nome,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: _ink,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 48,
                                            child: Icon(
                                              Icons.location_on,
                                              size: 30,
                                              color: Color(0xFF585E5D),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (locals.isEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: _surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _query.trim().isEmpty
                                ? 'Nenhum local nesta cidade'
                                : 'Nenhum local encontrado',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.trim().isEmpty
                                ? 'Cadastre um local para começar.'
                                : 'Tente outro nome, endereço ou categoria.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                          if (_query.trim().isEmpty)
                            TextButton(
                              onPressed: () => showLocalForm(
                                context,
                                _service,
                                cidade: _city,
                              ),
                              child: const Text('Cadastrar local'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: height > 400 ? height * .18 : 16,
                child: Flex(
                  direction: height < 150 ? Axis.horizontal : Axis.vertical,
                  children: [
                    _MapAction(
                      tooltip: 'Centralizar mapa',
                      icon: Icons.my_location,
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        _mapController.value = Matrix4.identity();
                      },
                    ),
                    SizedBox(
                      height: height < 150 ? 0 : 10,
                      width: height < 150 ? 10 : 0,
                    ),
                    _MapAction(
                      tooltip: 'Camadas do mapa',
                      icon: Icons.layers_outlined,
                      onPressed: _chooseLayers,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _surface.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Text(
                      'Mapa ilustrativo',
                      style: TextStyle(fontSize: 10, color: Color(0xFF707775)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfile(List<Local> locals) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFE8ECE9),
          child: Icon(Icons.person_outline, color: _ink, size: 38),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Seu perfil',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 24),
      ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: const Text('Sua cidade'),
        subtitle: Text(_city),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _chooseCity(locals),
      ),
      ListTile(
        leading: const Icon(Icons.favorite_border),
        title: const Text('Locais salvos'),
        subtitle: Text(
          '${locals.where((local) => local.favorito).length} favoritos',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openResults(favorites: true),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.add_location_alt_outlined),
        title: const Text('Cadastrar local'),
        onTap: () => showLocalForm(context, _service, cidade: _city),
      ),
      ListTile(
        leading: const Icon(Icons.format_list_bulleted),
        title: const Text('Gerenciar locais'),
        subtitle: Text('${locals.length} locais cadastrados'),
        onTap: () => _openResults(),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _seeding ? null : _seed,
        icon: _seeding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_upload_outlined),
        label: Text(
          _seeding ? 'Cadastrando...' : 'Adicionar locais de exemplo',
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Adiciona os exemplos que ainda não existem. Os locais cadastrados são preservados.',
        style: TextStyle(fontSize: 12, color: _muted),
      ),
    ],
  );
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    elevation: 3,
    shadowColor: const Color(0x33000000),
    shape: const CircleBorder(side: BorderSide(color: Color(0xFFDDE1DE))),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: _ink, size: 21),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );
}
