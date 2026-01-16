import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class Donation {
  final String id;
  final String title;
  final String category;
  final String description;
  final String address;
  final String donorName;
  final String donorAvatar;
  final String postedTime;
  final int distance;
  final bool isFavorite;

  Donation({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.address,
    required this.donorName,
    required this.donorAvatar,
    required this.postedTime,
    required this.distance,
    this.isFavorite = false,
  });
}

class DonationsListScreen extends ConsumerStatefulWidget {
  const DonationsListScreen({super.key});

  @override
  ConsumerState<DonationsListScreen> createState() =>
      _DonationsListScreenState();
}

class _DonationsListScreenState extends ConsumerState<DonationsListScreen> {
  final List<Donation> _donations = [
    Donation(
      id: '1',
      title: 'Caixas de Leite',
      category: 'Laticínios',
      description: 'Caixas de leite integral com validade para 1 mês.',
      address: 'Rua das Flores, 123 - Centro',
      donorName: 'Mercado Bom Preço',
      donorAvatar: 'M',
      postedTime: 'há 15 min',
      distance: 1,
      isFavorite: true,
    ),
    Donation(
      id: '2',
      title: 'Pães Franceses',
      category: 'Pães e Massas',
      description: 'Pães franceses assados hoje de manhã.',
      address: 'Avenida Paulista, 1000',
      donorName: 'Padaria Pão Quente',
      donorAvatar: 'P',
      postedTime: 'há 30 min',
      distance: 2,
    ),
    Donation(
      id: '3',
      title: 'Frutas da Estação',
      category: 'Frutas e Legumes',
      description: 'Caixas com frutas da estação em perfeito estado.',
      address: 'Rua das Laranjeiras, 456',
      donorName: 'Hortifruti Natural',
      donorAvatar: 'H',
      postedTime: 'há 1h',
      distance: 3,
    ),
  ];

  // Estado de filtros
  final Set<String> _selectedCategories = <String>{};
  bool _showFavoritesOnly = false;

  List<Donation> get _filteredDonations {
    return _donations.where((d) {
      final matchFav = !_showFavoritesOnly || d.isFavorite;
      final matchCat =
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(d.category);
      return matchFav && matchCat;
    }).toList();
  }

  void _toggleFavorite(String donationId) {
    setState(() {
      final index = _donations.indexWhere((d) => d.id == donationId);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(
          isFavorite: !_donations[index].isFavorite,
        );
      }
    });
  }

  Future<void> _openFilters() async {
    final categories = _donations.map((d) => d.category).toSet().toList()
      ..sort();
    final tempSelected = Set<String>.from(_selectedCategories);
    bool tempFavOnly = _showFavoritesOnly;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Mostrar apenas favoritos'),
                value: tempFavOnly,
                onChanged: (v) {
                  tempFavOnly = v;
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              const Text('Categorias'),
              const SizedBox(height: 8),
              ...categories.map((c) {
                final selected = tempSelected.contains(c);
                return CheckboxListTile(
                  value: selected,
                  title: Text(c),
                  onChanged: (v) {
                    if (v == true) {
                      tempSelected.add(c);
                    } else {
                      tempSelected.remove(c);
                    }
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        tempSelected.clear();
                        tempFavOnly = false;
                        setState(() {});
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories
                            ..clear()
                            ..addAll(tempSelected);
                          _showFavoritesOnly = tempFavOnly;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _contactDonor(Donation donation) async {
    final message = Uri.encodeComponent(
      'Olá, tenho interesse na doação: ${donation.title}',
    );
    final whatsapp = Uri.parse('https://wa.me/?text=$message');
    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
      return;
    }
    final mail = Uri.parse(
      'mailto:contato@exemplo.com?subject=Interesse%20na%20doacao&body=$message',
    );
    if (await canLaunchUrl(mail)) {
      await launchUrl(mail);
    }
  }

  Future<void> _openDonationDetails(Donation donation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailsScreen(
          donation: donation,
          onToggleFavorite: () => _toggleFavorite(donation.id),
          onContact: () => _contactDonor(donation),
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openNewDonationForm() async {
    final created = await Navigator.push<Donation?>(
      context,
      MaterialPageRoute(builder: (_) => const NewDonationFormScreen()),
    );
    if (created != null) {
      setState(() {
        _donations.insert(0, created);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações Próximas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _filteredDonations.length,
        itemBuilder: (context, index) {
          final donation = _filteredDonations[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () => _openDonationDetails(donation),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            donation.donorAvatar,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donation.donorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${donation.distance} km • ${donation.postedTime}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            donation.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: donation.isFavorite
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(donation.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      donation.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation.description,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        donation.category,
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donation.address,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _contactDonor(donation),
                        child: const Text('Entrar em Contato'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openNewDonationForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Doação'),
      ),
    );
  }
}

class DonationDetailsScreen extends StatelessWidget {
  final Donation donation;
  final VoidCallback onToggleFavorite;
  final VoidCallback onContact;
  const DonationDetailsScreen({
    super.key,
    required this.donation,
    required this.onToggleFavorite,
    required this.onContact,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(donation.title),
        actions: [
          IconButton(
            icon: Icon(
              donation.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: donation.isFavorite ? Colors.red : null,
            ),
            onPressed: onToggleFavorite,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(donation.donorAvatar)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.donorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${donation.distance} km • ${donation.postedTime}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(donation.description),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                donation.category,
                style: TextStyle(color: Colors.green[800], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    donation.address,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContact,
                child: const Text('Entrar em Contato'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewDonationFormScreen extends StatefulWidget {
  const NewDonationFormScreen({super.key});
  @override
  State<NewDonationFormScreen> createState() => _NewDonationFormScreenState();
}

class _NewDonationFormScreenState extends State<NewDonationFormScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final donorNameController = TextEditingController();
  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    donorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Doação')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a categoria' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a descrição' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Endereço'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o endereço' : null,
              ),
              TextFormField(
                controller: donorNameController,
                decoration: const InputDecoration(labelText: 'Nome do doador'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome do doador' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    final now = DateTime.now().millisecondsSinceEpoch
                        .toString();
                    final donation = Donation(
                      id: now,
                      title: titleController.text.trim(),
                      category: categoryController.text.trim(),
                      description: descriptionController.text.trim(),
                      address: addressController.text.trim(),
                      donorName: donorNameController.text.trim(),
                      donorAvatar: donorNameController.text.isNotEmpty
                          ? donorNameController.text[0].toUpperCase()
                          : 'D',
                      postedTime: 'agora',
                      distance: 0,
                    );
                    Navigator.pop(context, donation);
                  },
                  child: const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension DonationExtension on Donation {
  Donation copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? address,
    String? donorName,
    String? donorAvatar,
    String? postedTime,
    int? distance,
    bool? isFavorite,
  }) {
    return Donation(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      address: address ?? this.address,
      donorName: donorName ?? this.donorName,
      donorAvatar: donorAvatar ?? this.donorAvatar,
      postedTime: postedTime ?? this.postedTime,
      distance: distance ?? this.distance,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
