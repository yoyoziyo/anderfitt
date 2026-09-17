import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

const libraryOrange = Color(0xFFFF6B00);

class TrainingMaterial {
  const TrainingMaterial({
    required this.asset,
    required this.category,
    required this.section,
    required this.subsection,
    required this.title,
  });
  final String asset;
  final String category;
  final String section;
  final String subsection;
  final String title;

  factory TrainingMaterial.fromAsset(String asset) {
    final parts = asset.split('/');
    final folder = parts[parts.length - 2];
    var file = parts.last.replaceAll(
      RegExp(r'\.pdf(?:\.pdf)?$', caseSensitive: false),
      '',
    );
    file = file
        .replaceAll(RegExp(r'\s*\(1\)$'), '')
        .replaceAll(RegExp(r'\)$'), '');
    final replacements = {
      'Adaptao': 'Adaptação',
      'Avanado': 'Avançado',
      'Intermedirio': 'Intermediário',
      'Iniciantes': 'Iniciante',
    };
    for (final entry in replacements.entries) {
      file = file.replaceAll(entry.key, entry.value);
    }
    const organization = {
      'adaptação': ('Adaptação', '', 'Adaptação'),
      'avançado feminino': (
        'Feminino',
        'Avançado',
        'Academia · Avançado · Feminino',
      ),
      'avançado masculino': (
        'Masculino',
        'Avançado',
        'Academia · Avançado · Masculino',
      ),
      'feminino em casa': ('Treino em casa', 'Feminino', 'Em casa · Feminino'),
      'iniciante feminino': (
        'Feminino',
        'Iniciante',
        'Academia · Iniciante · Feminino',
      ),
      'iniciante masculino': (
        'Masculino',
        'Iniciante',
        'Academia · Iniciante · Masculino',
      ),
      'intermediario feminino': (
        'Feminino',
        'Intermediário',
        'Academia · Intermediário · Feminino',
      ),
      'intermediario masculino': (
        'Masculino',
        'Intermediário',
        'Academia · Intermediário · Masculino',
      ),
      'masculino em casa': (
        'Treino em casa',
        'Masculino',
        'Em casa · Masculino',
      ),
      'receitas': ('Receitas', '', 'Nutrição'),
    };
    final group = organization[folder] ?? (folder, '', folder);
    return TrainingMaterial(
      asset: asset,
      section: group.$1,
      subsection: group.$2,
      category: group.$3,
      title: file,
    );
  }
}

class TrainingLibraryPage extends StatefulWidget {
  const TrainingLibraryPage({super.key, required this.isAdmin});
  final bool isAdmin;
  @override
  State<TrainingLibraryPage> createState() => _TrainingLibraryPageState();
}

class _TrainingLibraryPageState extends State<TrainingLibraryPage> {
  late final Future<List<TrainingMaterial>> materials = _load();
  String query = '';
  String? section;
  String? subsection;

  Future<List<TrainingMaterial>> _load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final list =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/pdfs/') &&
                  path.toLowerCase().endsWith('.pdf'),
            )
            .map(TrainingMaterial.fromAsset)
            .toList()
          ..sort((a, b) {
            final group = a.category.compareTo(b.category);
            return group == 0 ? a.title.compareTo(b.title) : group;
          });
    return list;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<TrainingMaterial>>(
    future: materials,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Text('Não foi possível carregar a biblioteca.'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final all = snapshot.data!;
      final visible = all.where((item) {
        final matchesCategory =
            item.section == section &&
            (subsection == null || item.subsection == subsection);
        final needle = query.trim().toLowerCase();
        return matchesCategory &&
            (needle.isEmpty ||
                item.title.toLowerCase().contains(needle) ||
                item.category.toLowerCase().contains(needle));
      }).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          if (section != null)
            TextButton.icon(
              onPressed: () => setState(() {
                if (subsection != null) {
                  subsection = null;
                } else {
                  section = null;
                }
                query = '';
              }),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(subsection == null ? 'Biblioteca' : section!),
            )
          else
            const Text(
              'CONTEÚDO OFFLINE',
              style: TextStyle(
                color: libraryOrange,
                fontSize: 11,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            subsection ?? section ?? 'Biblioteca',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle(all.length),
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 22),
          if (section == null)
            _categoryGrid(all)
          else if (_needsSubsection(section!) && subsection == null)
            _subsectionGrid(all)
          else ...[
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar nesta categoria',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            const SizedBox(height: 18),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    'Nenhum material encontrado.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ...visible.map((item) => _MaterialCard(item: item)),
          ],
        ],
      );
    },
  );

  bool _needsSubsection(String value) =>
      value == 'Masculino' || value == 'Feminino' || value == 'Treino em casa';

  String _subtitle(int total) {
    if (section == null) {
      return widget.isAdmin
          ? '$total materiais disponíveis para os alunos.'
          : 'Escolha uma categoria para começar.';
    }
    if (subsection == null && _needsSubsection(section!)) {
      return section == 'Treino em casa'
          ? 'Escolha o perfil do treino.'
          : 'Escolha o nível de treinamento.';
    }
    return 'Materiais disponíveis sem internet.';
  }

  Widget _categoryGrid(List<TrainingMaterial> all) {
    const categories = [
      ('Masculino', Icons.male_rounded),
      ('Feminino', Icons.female_rounded),
      ('Treino em casa', Icons.home_work_outlined),
      ('Adaptação', Icons.accessibility_new_rounded),
      ('Receitas', Icons.restaurant_menu_rounded),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final value = categories[index];
        final count = all.where((item) => item.section == value.$1).length;
        return _LibraryTile(
          title: value.$1,
          caption: '$count ${count == 1 ? 'material' : 'materiais'}',
          icon: value.$2,
          onTap: () => setState(() => section = value.$1),
        );
      },
    );
  }

  Widget _subsectionGrid(List<TrainingMaterial> all) {
    final options = section == 'Treino em casa'
        ? const [
            ('Masculino', Icons.male_rounded),
            ('Feminino', Icons.female_rounded),
          ]
        : const [
            ('Iniciante', Icons.looks_one_outlined),
            ('Intermediário', Icons.looks_two_outlined),
            ('Avançado', Icons.looks_3_outlined),
          ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final value = options[index];
        final count = all
            .where(
              (item) => item.section == section && item.subsection == value.$1,
            )
            .length;
        return _LibraryTile(
          title: value.$1,
          caption: count == 0
              ? 'Em breve'
              : '$count ${count == 1 ? 'material' : 'materiais'}',
          icon: value.$2,
          enabled: count > 0,
          onTap: () => setState(() => subsection = value.$1),
        );
      },
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.caption,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });
  final String title;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .4,
    child: Material(
      color: const Color(0xFF17191D),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: libraryOrange.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: libraryOrange),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                caption,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.item});
  final TrainingMaterial item;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: const Color(0xFF17191D),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PdfReaderPage(material: item))),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 58,
              decoration: BoxDecoration(
                color: libraryOrange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: libraryOrange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(
                      color: libraryOrange,
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(
                        Icons.offline_pin_outlined,
                        size: 14,
                        color: Colors.white38,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Disponível sem internet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    ),
  );
}

class PdfReaderPage extends StatefulWidget {
  const PdfReaderPage({super.key, required this.material});
  final TrainingMaterial material;
  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  late final PdfControllerPinch controller = PdfControllerPinch(
    document: PdfDocument.openData(_loadPdfBytes()),
  );
  int page = 1;
  int pages = 0;
  bool failed = false;
  late final Future<int> savedPage;
  String get progressKey => 'pdf_page_${widget.material.asset}';

  Future<Uint8List> _loadPdfBytes() async {
    final data = await rootBundle.load(widget.material.asset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  void initState() {
    super.initState();
    savedPage = SharedPreferences.getInstance().then(
      (prefs) => prefs.getInt(progressKey) ?? 1,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> move(bool forward) async {
    if (failed || pages == 0) return;
    final target = (page + (forward ? 1 : -1)).clamp(1, pages);
    if (target != page) {
      await controller.animateToPage(
        pageNumber: target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.material.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            widget.material.category,
            style: const TextStyle(fontSize: 10, color: libraryOrange),
          ),
        ],
      ),
    ),
    body: failed
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Não foi possível abrir este material.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : PdfViewPinch(
            controller: controller,
            onDocumentLoaded: (document) async {
              pages = document.pagesCount;
              final restored = (await savedPage).clamp(1, pages);
              if (!mounted) return;
              controller.jumpToPage(restored);
              setState(() => page = restored);
            },
            onPageChanged: (value) {
              setState(() => page = value);
              SharedPreferences.getInstance().then(
                (prefs) => prefs.setInt(progressKey, value),
              );
            },
            onDocumentError: (_) => setState(() => failed = true),
          ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFF111316),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Página anterior',
              onPressed: page > 1 ? () => move(false) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                pages == 0 ? 'Carregando…' : 'Página $page de $pages',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filled(
              tooltip: 'Próxima página',
              onPressed: pages > 0 && page < pages ? () => move(true) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ),
  );
}
