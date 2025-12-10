import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/notification_preferences_provider.dart';

// Exemplo fixo de categorias - ideal usar dinamicamente do provider de produtos
const allCategories = [
  'Frescos', 'Congelados', 'Bebidas', 'Grãos', 'Limpeza', 'Outros'
];

class NotificationPreferencesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text('Preferências de Notificação')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Dias de antecedência do alerta', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: prefs.diasAntes.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '${prefs.diasAntes} dias',
            onChanged: (v) => notifier.setDiasAntes(v.round()),
          ),
          const SizedBox(height: 24),
          Text('Horário preferido para envio', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            title: Text('${prefs.horario.hour.toString().padLeft(2, '0')}:${prefs.horario.minute.toString().padLeft(2, '0')}h'),
            trailing: Icon(Icons.access_time),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: prefs.horario,
              );
              if (t != null) notifier.setHorario(t);
            },
          ),
          const Divider(height: 32),
          Text('Silenciar categorias', style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: allCategories.map((cat) => FilterChip(
              label: Text(cat),
              selected: prefs.categoriasSilenciadas.contains(cat),
              onSelected: (_) => notifier.toggleCategoria(cat),
            )).toList(),
          ),
          const Divider(height: 32),
          SwitchListTile.adaptive(
            value: prefs.notificacaoMotivacional,
            title: Text('Receber notificações motivacionais'),
            onChanged: notifier.setMotivacional,
          ),
          const SizedBox(height: 36),
          TextButton.icon(
            onPressed: notifier.reset,
            icon: Icon(Icons.restart_alt),
            label: Text('Restaurar padrão'),
          ),
        ],
      ),
    );
  }
}
