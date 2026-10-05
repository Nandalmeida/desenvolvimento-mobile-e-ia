# TarefaIA — Proposta de Solução

## 1. Situação-problema

**Empresa (fictícia):** *Studio Brisa*, agência de design com 8 pessoas.

**Problema real:** as demandas chegam de forma desorganizada (mensagens longas de clientes, anotações soltas, áudios transcritos, e-mails). Cada profissional precisa ler tudo, separar o que é tarefa, decidir prioridade e quebrar em passos. Esse trabalho manual consome tempo, e tarefas acabam esquecidas ou mal priorizadas.

**Por que cabe em 3 meses:** o escopo é um único fluxo (texto livre → tarefas organizadas), sem backend próprio, sem login, sem notificações. A parte de IA consome uma API pronta.

## 2. Escopo, objetivos e público-alvo

**Escopo da 1ª etapa:** lista de tarefas local (criar, concluir, excluir, priorizar, subtarefas) + assistente de IA.

**Objetivos**
- Reduzir o tempo entre receber uma demanda e ter tarefas claras e priorizadas.
- Oferecer uma lista de tarefas simples, rápida e usável com uma mão.

**Público-alvo:** profissionais autônomos, estudantes e pequenas equipes que recebem demandas em texto livre.

**Funcionalidade inteligente principal:** *Organizar com IA* — o usuário cola um texto livre e um LLM pré-treinado devolve tarefas curtas, com prioridade (alta/média/baixa) e subtarefas. Complemento: *Sugerir subtarefas* para qualquer tarefa existente.

**Fora do escopo (próximas etapas):** notificações e lembretes, login/contas, sincronização na nuvem, marcação de pessoas, voz e OCR.

## 3. Requisitos

### Funcionais
| ID | Requisito |
|----|-----------|
| RF01 | Criar tarefa com título e prioridade |
| RF02 | Marcar/desmarcar tarefa como concluída |
| RF03 | Excluir tarefa (deslizar para o lado) |
| RF04 | Ordenar lista: pendentes primeiro, depois por prioridade |
| RF05 | Exibir progresso (concluídas/total) |
| RF06 | Adicionar e concluir subtarefas |
| RF07 | Persistir dados localmente no dispositivo |
| RF08 | Enviar texto livre à IA e exibir prévia das tarefas sugeridas |
| RF09 | Permitir selecionar quais sugestões entram na lista |
| RF10 | Sugerir subtarefas por IA para uma tarefa existente |

### Não funcionais
| ID | Requisito |
|----|-----------|
| RNF01 | Interface simples, responsiva (celular/tablet) e com tema claro/escuro |
| RNF02 | Funcionar offline para tudo, exceto os recursos de IA |
| RNF03 | Resposta da IA em até ~25 s, com indicador de carregamento e timeout |
| RNF04 | Erros de rede/IA tratados com mensagem clara, sem travar o app |
| RNF05 | Chave da API fora do código-fonte (`--dart-define`) |
| RNF06 | Texto enviado à IA somente quando o usuário aciona o recurso |
| RNF07 | Resposta da IA validada (JSON, prioridade limitada a 0–2) antes de usar |

### Específicos da integração com IA
- Prompt com formato de saída fixo (JSON) e baixa temperatura para respostas estáveis.
- Usuário sempre confirma o que a IA sugeriu antes de salvar (humano no controle).
- Tratamento de resposta malformada, vazia ou fora do formato.

## 4. Fluxo de dados com a IA

```
[Tela: texto livre] → AiService.extractTasks()
   → POST HTTPS (Gemini generateContent, resposta em JSON)
   → parse + validação → List<Task>
   → [Tela: prévia com checkboxes] → confirmar → lista principal → salvo localmente
```

## 5. Cronograma (12 semanas)

| Semanas | Entrega |
|---------|---------|
| 1–2 | Levantamento do problema, requisitos, protótipo de telas |
| 3–5 | CRUD de tarefas, persistência local, navegação |
| 6–7 | Subtarefas, prioridade, progresso |
| 8–9 | Integração com a API de IA (extração de tarefas) |
| 10 | Subtarefas por IA, tratamento de erros |
| 11 | Testes com usuários, ajustes de usabilidade |
| 12 | Documentação, apresentação, vídeo de demonstração |

## 6. Riscos
- **Custo/limite da API:** usar o plano gratuito e limitar o tamanho do texto enviado.
- **Respostas inconsistentes:** prompt com formato fixo + validação no app.
- **Privacidade:** avisar o usuário de que o texto é enviado a um serviço externo.

## 7. Como rodar

```bash
flutter create tarefa_ia          # gera as pastas android/ ios/ etc.
# copie pubspec.yaml e a pasta lib/ deste projeto por cima
cd tarefa_ia
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

A chave gratuita é gerada no Google AI Studio. Se o nome do modelo padrão for descontinuado, passe outro com `--dart-define=GEMINI_MODEL=...`.

**Android (build release):** adicione no `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`:
`<uses-permission android:name="android.permission.INTERNET"/>`
