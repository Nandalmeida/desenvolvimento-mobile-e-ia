import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/ai_service.dart';

/// Fluxo: usuário escreve texto livre -> app envia ao LLM -> recebe JSON ->
/// exibe prévia das tarefas -> usuário confirma e elas voltam para a lista.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _ai = AiService();
  bool _loading = false;
  String? _error;
  List<Task> _suggested = [];
  final Set<String> _selected = {};

  static const _labels = ['Baixa', 'Média', 'Alta'];
  static const _colors = [Colors.green, Colors.orange, Colors.red];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _organize() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _suggested = [];
      _selected.clear();
    });
    try {
      final tasks = await _ai.extractTasks(text);
      if (!mounted) return;
      setState(() {
        _suggested = tasks;
        _selected.addAll(tasks.map((t) => t.id));
        if (tasks.isEmpty) _error = 'Não encontrei tarefas nesse texto. Tente detalhar mais.';
      });
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirm() {
    Navigator.pop(context, _suggested.where((t) => _selected.contains(t.id)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente de IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Escreva ou cole tudo o que você precisa fazer. A IA separa em tarefas, define prioridades e sugere subtarefas.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Ex.: preciso entregar o relatório até sexta, marcar dentista e comprar presente da minha mãe...',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _organize,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Organizando...' : 'Organizar com IA'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_suggested.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Tarefas sugeridas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final t in _suggested)
              Card(
                child: CheckboxListTile(
                  value: _selected.contains(t.id),
                  onChanged: (v) => setState(() {
                    v == true ? _selected.add(t.id) : _selected.remove(t.id);
                  }),
                  title: Text(t.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.flag, size: 14, color: _colors[t.priority]),
                        const SizedBox(width: 4),
                        Text(_labels[t.priority]),
                      ]),
                      for (final s in t.subtasks) Text('• ${s.title}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selected.isEmpty ? null : _confirm,
              child: Text('Adicionar ${_selected.length} à lista'),
            ),
          ],
        ],
      ),
    );
  }
}
