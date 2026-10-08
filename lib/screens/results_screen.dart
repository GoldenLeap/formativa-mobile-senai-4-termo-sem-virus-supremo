import 'package:flutter/material.dart';

import '../models/local.dart';
import '../services/local_service.dart';
import '../utils/search.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/local_card.dart';
import '../widgets/local_form.dart';
import 'details_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.service,
    this.cidade = 'São Paulo',
    this.query = '',
    this.favoritos = false,
  });

  final LocalService service;
  final String cidade;
  final String query;
  final bool favoritos;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final TextEditingController _searchController;
  late Stream<List<Local>> _localsStream;
  late String _cidade;
  late bool _showFavorites;
  String _category = 'Todos';
  double _minimumRating = 0;

  static const _categories = {
    'Todos': 'Todos',
    'Academia': 'Academias',
    'Restaurante': 'Restaurantes',
    'Hospital': 'Hospitais',
    'Café': 'Cafés',
    'Parque': 'Parques',
    'Livraria': 'Livrarias',
    'Mercado': 'Mercados',
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _cidade = widget.cidade;
    _showFavorites = widget.favoritos;
    _localsStream = widget.service.listarLocais();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chooseCity() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final city = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Selecionar cidade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          for (final city in {'São Paulo', 'Campinas', 'Jundiai', _cidade})
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(city),
              trailing: _cidade == city ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(sheetContext, city),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
    if (mounted && city != null) setState(() => _cidade = city);
  }

  Future<void> _chooseRating() async {
    var rating = _minimumRating;
    final selected = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Avaliação mínima',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in {
                      0.0: 'Todas',
                      4.0: '4.0 ou mais',
                      4.5: '4.5 ou mais',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: rating == entry.key,
                        onSelected: (_) =>
                            setSheetState(() => rating = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, rating),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (mounted && selected != null) setState(() => _minimumRating = selected);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _category = 'Todos';
      _minimumRating = 0;
    });
  }

  Future<void> _openDetails(Local local) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailsScreen(service: widget.service, local: local),
      ),
    );
    if (!mounted) return;
    if (result is Local) {
      Navigator.pop(context, result);
    } else if (result == 1) {
      setState(() => _showFavorites = true);
    } else if (result == 2) {
      Navigator.pop(context, 2);
    }
  }

  bool _matchesCategory(Local local) {
    if (_category == 'Todos') return true;
    final category = normalizeSearch(local.categoria);
    return category == normalizeSearch(_category) ||
        category == normalizeSearch(_categories[_category] ?? _category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAF9),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _showFavorites ? 'Favoritos' : 'Resultados',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Voltar ao mapa',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Cadastrar local',
            icon: const Icon(Icons.add),
            onPressed: () =>
                showLocalForm(context, widget.service, cidade: _cidade),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Buscar locais, endereços ou categorias...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar pesquisa',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchController.clear()),
                                ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD0D5D1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFD0D5D1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filtrar por avaliação',
                      onPressed: _chooseRating,
                      icon: Icon(
                        Icons.tune,
                        size: 20,
                        color: _minimumRating > 0
                            ? const Color(0xFF353B3D)
                            : const Color(0xFF858C89),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFD0D5D1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _chooseCity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cidade,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in _categories.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: _category == entry.key,
                            showCheckmark: false,
                            selectedColor: const Color(0xFF353B3D),
                            backgroundColor: const Color(0xFFEBEEEC),
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: _category == entry.key
                                  ? Colors.white
                                  : const Color(0xFF555C58),
                            ),
                            onSelected: (_) =>
                                setState(() => _category = entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_minimumRating > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Avaliação: ${_minimumRating.toStringAsFixed(1)} ou mais',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777D7A),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Local>>(
              stream: _localsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _empty(
                    Icons.cloud_off_outlined,
                    'Não foi possível carregar os locais.',
                    'Confira a conexão e as permissões do Firestore.',
                    action: 'Tentar novamente',
                    onAction: () => setState(
                      () => _localsStream = widget.service.listarLocais(),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data!;
                final visible =
                    all
                        .where(
                          (local) =>
                              normalizeSearch(local.cidade) ==
                                  normalizeSearch(_cidade) &&
                              (!_showFavorites || local.favorito) &&
                              matchesLocal(local, _searchController.text) &&
                              _matchesCategory(local) &&
                              local.avaliacao >= _minimumRating,
                        )
                        .toList()
                      ..sort((a, b) => a.distancia.compareTo(b.distancia));
                if (visible.isEmpty) {
                  if (all.isEmpty) {
                    return _empty(
                      Icons.location_on_outlined,
                      'Nenhum local cadastrado.',
                      'Cadastre o primeiro local para começar.',
                      action: 'Cadastrar local',
                      onAction: () => showLocalForm(
                        context,
                        widget.service,
                        cidade: _cidade,
                      ),
                    );
                  }
                  final noFavorites =
                      _showFavorites &&
                      !all.any(
                        (local) =>
                            local.favorito &&
                            normalizeSearch(local.cidade) ==
                                normalizeSearch(_cidade),
                      );
                  return _empty(
                    noFavorites ? Icons.favorite_border : Icons.search_off,
                    noFavorites
                        ? 'Você ainda não tem favoritos nesta cidade.'
                        : 'Nenhum local encontrado.',
                    noFavorites
                        ? 'Toque no coração na tela de detalhes para salvar um local.'
                        : 'Tente outra pesquisa, cidade ou filtro.',
                    action: noFavorites ? 'Explorar locais' : 'Limpar filtros',
                    onAction: noFavorites
                        ? () => setState(() => _showFavorites = false)
                        : _clearFilters,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) => LocalCard(
                    local: visible[index],
                    onTap: () => _openDetails(visible[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        currentIndex: _showFavorites ? 1 : 0,
        onTap: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (index == 0) {
            Navigator.pop(context, 0);
          } else if (index == 1) {
            setState(() => _showFavorites = true);
          } else {
            Navigator.pop(context, 2);
          }
        },
      ),
    );
  }

  Widget _empty(
    IconData icon,
    String title,
    String description, {
    required String action,
    required VoidCallback onAction,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777D7A)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
