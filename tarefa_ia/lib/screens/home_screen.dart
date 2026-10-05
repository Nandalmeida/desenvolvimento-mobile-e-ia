import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/ai_service.dart';
import '../services/task_storage.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = TaskStorage();
  final _ai = AiService();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _busyTaskId; // tarefa aguardando resposta da IA

  static const _priorityLabels = ['Baixa', 'Média', 'Alta'];
  static const _priorityColors = [Colors.green, Colors.orange, Colors.red];

  @override
  void initState() {
    super.initState();
    _storage.load().then((t) {
      if (!mounted) return;
      setState(() {
        _tasks = t;
        _loading = false;
      });
    });
  }

  Future<void> _persist() => _storage.save(_tasks);

  List<Task> get _sorted {
    final list = [..._tasks];
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addTaskDialog() async {
    final controller = TextEditingController();
    int priority = 1;
    final created = await showDialog<Task>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nova tarefa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'O que precisa ser feito?'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Baixa')),
                  ButtonSegment(value: 1, label: Text('Média')),
                  ButtonSegment(value: 2, label: Text('Alta')),
                ],
                selected: {priority},
                onSelectionChanged: (s) => setLocal(() => priority = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx, Task(id: Task.newId(), title: title, priority: priority));
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    if (created != null) {
      setState(() => _tasks.add(created));
      await _persist();
    }
  }

  Future<void> _openAssistant() async {
    final result = await Navigator.push<List<Task>>(
      context,
      MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _tasks.addAll(result));
      await _persist();
      _snack('${result.length} tarefa(s) adicionada(s).');
    }
  }

  Future<void> _suggestSubtasks(Task task) async {
    setState(() => _busyTaskId = task.id);
    try {
      final suggestions = await _ai.suggestSubtasks(task.title);
      final existing = task.subtasks.map((s) => s.title.toLowerCase()).toSet();
      final fresh = suggestions.where((s) => !existing.contains(s.toLowerCase()));
      setState(() => task.subtasks.addAll(fresh.map((s) => SubTask(title: s))));
      await _persist();
    } on AiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busyTaskId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _sorted;
    final doneCount = _tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        actions: [
          IconButton(
            tooltip: 'Assistente de IA',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _openAssistant,
          ),
        ],
        bottom: _tasks.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(value: doneCount / _tasks.length),
                      ),
                      const SizedBox(width: 12),
                      Text('$doneCount/${_tasks.length}'),
                    ],
                  ),
                ),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _taskTile(tasks[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tarefa'),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checklist, size: 64),
              const SizedBox(height: 16),
              const Text('Nenhuma tarefa ainda', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'Adicione uma tarefa ou cole um texto no assistente de IA para organizar tudo de uma vez.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openAssistant,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Usar assistente de IA'),
              ),
            ],
          ),
        ),
      );

  Widget _taskTile(Task task) {
    final color = _priorityColors[task.priority];
    final titleStyle = TextStyle(
      decoration: task.done ? TextDecoration.lineThrough : null,
      color: task.done ? Theme.of(context).disabledColor : null,
    );

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _tasks.removeWhere((t) => t.id == task.id));
        _persist();
      },
      child: ExpansionTile(
        key: PageStorageKey(task.id),
        leading: Checkbox(
          value: task.done,
          onChanged: (v) {
            setState(() => task.done = v ?? false);
            _persist();
          },
        ),
        title: Text(task.title, style: titleStyle),
        subtitle: Row(
          children: [
            Icon(Icons.flag, size: 14, color: color),
            const SizedBox(width: 4),
            Text(_priorityLabels[task.priority]),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text('${task.subtasks.where((s) => s.done).length}/${task.subtasks.length} subtarefas'),
            ],
          ],
        ),
        children: [
          for (final s in task.subtasks)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              controlAffinity: ListTileControlAffinity.leading,
              value: s.done,
              title: Text(s.title),
              onChanged: (v) {
                setState(() => s.done = v ?? false);
                _persist();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _busyTaskId == task.id
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton.icon(
                      onPressed: () => _suggestSubtasks(task),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Sugerir subtarefas com IA'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
