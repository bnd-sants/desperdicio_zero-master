import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importação removida pois o arquivo não existe
// Será usado o ElevatedButton nativo do Flutter

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
  ConsumerState<DonationsListScreen> createState() => _DonationsListScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doações Próximas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _donations.length,
        itemBuilder: (context, index) {
          final donation = _donations[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: () {
                // TODO: Navigate to donation details
              },
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
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
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
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
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
                        onPressed: () {
                          // TODO: Implement contact donor
                        },
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text('Formulário de Nova Doação'),
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Doação'),
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
