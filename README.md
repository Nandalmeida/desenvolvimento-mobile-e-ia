# TarefaAI

Aplicativo móvel em Flutter para gerenciar tarefas (to-do list) com um **assistente de IA** que transforma texto livre em tarefas organizadas e priorizadas.

A proposta completa do projeto (situação-problema, escopo, requisitos e cronograma) está em [PROPOSTA.md](PROPOSTA.md).

## 8. Integrantes
| RA | Nome |
|----|------|
| 25002085 | Maria Fernanda de Almeida Lopes Borges |
| 25000517 | Leonardo da Silva Fonseca |

## O que o app faz

### Lista de tarefas
- **Criar tarefa** com título e prioridade (baixa, média ou alta), pelo botão **+ Tarefa**.
- **Concluir tarefa** marcando a caixa de seleção.
- **Excluir tarefa** deslizando o item para a esquerda.
- **Ordenação automática:** pendentes primeiro e, dentro deles, por prioridade.
- **Barra de progresso** no topo com o total de tarefas concluídas.
- **Subtarefas:** toque em uma tarefa para expandir, ver e marcar as subtarefas.
- **Dados salvos no aparelho** (`shared_preferences`), sem login e sem servidor próprio.

### Assistente de IA (ícone ✨ no topo)
- **Organizar com IA:** o usuário escreve ou cola um texto livre, por exemplo *"preciso entregar o relatório até sexta, marcar dentista e comprar presente da minha mãe"*. O app envia o texto ao modelo Gemini, que devolve tarefas curtas, com prioridade e subtarefas. O usuário vê uma prévia, escolhe quais manter e confirma.
- **Sugerir subtarefas com IA:** dentro de uma tarefa expandida, o botão quebra a tarefa em 3 a 5 passos.

### Tratamento de erros da IA
- Se o serviço estiver sobrecarregado (503, 429), o app tenta de novo e passa para modelos de reserva.
- Se o modelo não existir (404), passa direto para o próximo da lista.
- Erros de chave (400, 401, 403) aparecem na tela com a mensagem do Google.

## Fluxo de dados com a IA

```
Texto do usuário -> AiService (HTTPS, Gemini generateContent, resposta em JSON)
   -> validação e conversão em tarefas -> prévia na tela -> confirmação -> lista local
```

## Estrutura do projeto

```
lib/
  main.dart                      # ponto de entrada e tema
  models/task.dart               # Task e SubTask
  screens/home_screen.dart       # lista de tarefas
  screens/ai_assistant_screen.dart  # assistente de IA
  services/ai_service.dart       # chamadas à API do Gemini
  services/task_storage.dart     # armazenamento local
test/widget_test.dart            # testes de widget
```

## Requisitos para executar

1. **Flutter SDK** instalado (`flutter doctor` sem erros na parte do Android).
2. **Android Studio** com o Android SDK e o **NDK** instalados (se o build falhar pedindo o NDK, instale-o em *SDK Manager > SDK Tools > NDK (Side by side)*).
3. Um **emulador Android** aberto ou um **celular Android** com depuração USB ligada.
4. Uma **chave de API do Gemini**, gratuita, criada em [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey).
5. Permissão de internet no Android, em `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` e antes de `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

## Como executar pelo terminal

Na pasta do projeto (a que contém o `pubspec.yaml`):

```bash
# 1. Baixar as dependências
flutter pub get

# 2. Ver os dispositivos disponíveis (o emulador aparece como emulator-5554)
flutter devices

# 3. Rodar o app passando a chave da API
flutter run -d emulator-5554 --dart-define=GEMINI_API_KEY=SUA_CHAVE
```

Se o emulador ainda não estiver aberto:

```bash
flutter emulators
flutter emulators --launch NOME_DO_EMULADOR
```

Aguarde a tela inicial do Android aparecer antes de rodar o app. A primeira compilação demora alguns minutos.

### Sobre a chave e o modelo
- A chave **não fica no código**. Ela é lida em `String.fromEnvironment('GEMINI_API_KEY')`, e por isso precisa ser passada no `--dart-define` a cada execução.
- Depois de mudar a chave ou o modelo, **pare o app e rode de novo** (o hot reload não relê o `--dart-define`).
- O modelo padrão é `gemini-flash-latest`, com modelos de reserva. Para escolher outro:
  ```bash
  flutter run -d emulator-5554 \
    --dart-define=GEMINI_API_KEY=SUA_CHAVE \
    --dart-define=GEMINI_MODEL=nome-do-modelo
  ```
- **Nunca** coloque a chave em arquivos que vão para o GitHub. Se ela vazar, apague no AI Studio e crie outra.

### Executar os testes

```bash
flutter test
```

## Problemas comuns

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| "Chave da API não configurada" | App iniciado sem `--dart-define` | Rodar pelo terminal com o comando acima |
| Erro 404 | Nome do modelo não existe mais | Passar outro com `GEMINI_MODEL` (lista em `curl "https://generativelanguage.googleapis.com/v1beta/models" -H "x-goog-api-key: SUA_CHAVE"`) |
| Erro 503 | Modelo sobrecarregado | O app já tenta de novo e troca de modelo; se persistir, tentar em alguns minutos |
| Erro 429 | Limite do plano gratuito | Esperar ou usar um modelo "lite" |
| Erro 401 ou 403 | Chave inválida ou sem permissão | Criar nova chave no AI Studio |
| Build falha pedindo o NDK | NDK não instalado | Instalar pelo Android Studio (SDK Tools) |
| `emulator-5554 is offline` | Android ainda iniciando | Esperar o boot e rodar `flutter devices` de novo |
| Acentos não funcionam no emulador | Teclas mortas do teclado do PC | Usar o teclado virtual do emulador ou colar o texto |
| Erros no VS Code depois do `flutter clean` | Pacotes apagados | Rodar `flutter pub get` |

## Privacidade

O texto digitado no assistente é enviado ao serviço de IA do Google somente quando o usuário toca em **Organizar com IA** ou **Sugerir subtarefas**. No plano gratuito, o conteúdo pode ser usado pelo Google para melhorar seus produtos, então não use dados sensíveis.

## Próximas etapas (fora do escopo atual)

Notificações e lembretes, login e sincronização na nuvem, marcação de pessoas, entrada por voz e leitura de imagens (OCR).
