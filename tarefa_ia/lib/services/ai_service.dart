import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// Erro temporário (503, 429...) ou modelo inexistente (404): vale tentar de novo
/// ou passar para o próximo modelo da lista.
class _RetryableException implements Exception {
  final String message;
  final bool skipModel; // true = não adianta repetir neste modelo
  _RetryableException(this.message, {this.skipModel = false});
}

/// Cliente de LLM pré-treinado (Google Gemini via API REST).
///
/// A chave NÃO fica no código. Rode o app com:
///   flutter run --dart-define=GEMINI_API_KEY=sua_chave
/// (Opcional) modelo preferido: --dart-define=GEMINI_MODEL=nome-do-modelo
class AiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-flash-latest');

  /// Modelos de reserva, usados em ordem se o principal estiver sobrecarregado.
  static const _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.5-flash',
  ];

  /// Fluxo principal: texto livre -> lista estruturada de tarefas priorizadas.
  Future<List<Task>> extractTasks(String freeText) async {
    final prompt = '''
Você é um assistente de produtividade. Leia o texto do usuário e extraia as tarefas.
Responda SOMENTE com JSON válido, neste formato:
{"tasks":[{"title":"verbo no infinitivo + objeto, curto","priority":0|1|2,"subtasks":["..."]}]}
Regras: priority 2 = urgente/importante, 1 = normal, 0 = pode esperar.
Use no máximo 3 subtarefas por tarefa, e apenas se realmente ajudarem. Português do Brasil.

Texto do usuário:
"""
$freeText
"""''';
    final data = await _generateJson(prompt);
    final list = (data['tasks'] as List? ?? []);
    final base = Task.newId();
    var i = 0;
    return list
        .map((e) {
          final m = e as Map<String, dynamic>;
          return Task(
            id: '$base-${i++}',
            title: (m['title'] as String? ?? '').trim(),
            priority: ((m['priority'] as num?)?.toInt() ?? 1).clamp(0, 2),
            subtasks: (m['subtasks'] as List? ?? [])
                .map((s) => SubTask(title: s.toString()))
                .toList(),
          );
        })
        .where((t) => t.title.isNotEmpty)
        .toList();
  }

  /// Quebra uma tarefa em subtarefas acionáveis.
  Future<List<String>> suggestSubtasks(String taskTitle) async {
    final prompt = '''
Quebre a tarefa abaixo em 3 a 5 subtarefas curtas e acionáveis, em português do Brasil.
Responda SOMENTE com JSON válido: {"subtasks":["..."]}

Tarefa: $taskTitle''';
    final data = await _generateJson(prompt);
    return (data['subtasks'] as List? ?? []).map((e) => e.toString()).toList();
  }

  /// Tenta o modelo preferido e, se estiver sobrecarregado ou indisponível,
  /// repete uma vez e passa para os modelos de reserva.
  Future<Map<String, dynamic>> _generateJson(String prompt) async {
    if (_apiKey.isEmpty) {
      throw AiException(
          'Chave da API não configurada. Rode com --dart-define=GEMINI_API_KEY=...');
    }

    final models = <String>{_model, ..._fallbackModels}.toList();
    String lastMessage = '';

    for (final model in models) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          return await _callModel(model, prompt);
        } on _RetryableException catch (e) {
          lastMessage = e.message;
          if (e.skipModel) break; // vai direto para o próximo modelo
          if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    throw AiException(
        'O serviço de IA está indisponível no momento. Tente novamente em instantes. $lastMessage'
            .trim());
  }

  Future<Map<String, dynamic>> _callModel(String model, String prompt) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.3,
              },
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        final detail = _errorDetail(res);
        final msg = 'Erro do serviço de IA (${res.statusCode}). $detail'.trim();
        if (res.statusCode == 404) {
          throw _RetryableException(msg, skipModel: true);
        }
        if ([429, 500, 502, 503, 504].contains(res.statusCode)) {
          throw _RetryableException(msg);
        }
        throw AiException(msg); // 400, 401, 403...: não adianta repetir
      }

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      var text = body['candidates'][0]['content']['parts'][0]['text'] as String;
      text = text.replaceAll(RegExp(r'^```(?:json)?|```$', multiLine: true), '').trim();
      return jsonDecode(text) as Map<String, dynamic>;
    } on _RetryableException {
      rethrow;
    } on AiException {
      rethrow;
    } on TimeoutException {
      throw _RetryableException('Tempo de resposta esgotado.');
    } on FormatException {
      throw AiException('A IA devolveu uma resposta inesperada. Tente novamente.');
    } catch (_) {
      throw AiException('Falha de conexão com o serviço de IA.');
    }
  }

  String _errorDetail(http.Response res) {
    try {
      final err = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (err['error']?['message'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }
}
