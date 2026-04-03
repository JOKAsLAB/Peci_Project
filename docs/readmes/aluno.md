# Aluno (Flutter Mobile)

Aplicacao mobile do aluno para pratica gamificada, perfil e exploracao de conteudo.

## Navegacao rapida

- [Index da documentacao](index.md)
- [Master end-to-end](master.md)
- [Projeto (visao geral)](project.md)
- [Estrutura do repositorio](repo_estrutura.md)
- [Scripts (run e testes)](scripts.md)
- [Backend](backend.md)
- [Admin_Docente](admin_docente.md)
- [Aluno](aluno.md)
- [AI Engine](ai_engine.md)
- [Infrastructure](infrastructure.md)
- [Build](build.md)
- [Website promocional](website_promocional.md)

## Stack

- Flutter
- Riverpod
- GoRouter
- Drift (persistencia local)

## Objetivo funcional

Este modulo entrega a experiencia mobile do aluno:

- navegacao principal de estudo,
- fluxo de autenticacao no cliente,
- pratica e progresso,
- componentes de perfil e suporte de UI.

## Estrutura principal

```text
aluno/
├── lib/
│   ├── core/
│   ├── data/
│   ├── features/
│   ├── presentation/
│   └── main.dart
├── android/
├── ios/
├── windows/
├── test/
└── pubspec.yaml
```

## Estrutura de codigo (resumo)

- `lib/main.dart`: bootstrap da app.
- `lib/core/*`: router, tema e infraestrutura base da app.
- `lib/data/*`: dados locais/mock e persistencia local.
- `lib/features/*`: estado e logica por dominio.
- `lib/presentation/*`: ecras e componentes de interface.

## Para que serve

- Entregar a experiencia de estudo do aluno no telemovel.
- Executar pratica por exercicios e acompanhar progresso.
- Suportar fluxos de autenticacao e navegacao do cliente mobile.

## Quando e necessario

- Necessario quando a equipa esta a desenvolver/testar funcionalidades do aluno.
- Opcional para ciclos focados so em web/backend.

## Pre-requisitos

- Flutter SDK instalado
- Android SDK + `adb` no PATH
- Emulador Android disponivel

## Execucao local

```powershell
.\scripts\run\run_aluno.ps1
```

Alternativa manual:

```powershell
cd aluno
flutter pub get
flutter run
```

## Testes

Widget tests do modulo:

```powershell
.\scripts\test\run_aluno_widget_tests.ps1
```

Suite completa (web + backend + aluno):

```powershell
.\scripts\test\run_all_tests.ps1
```

## Observacoes

- O diretorio `build/` dentro de `aluno/` e gerado automaticamente.
- `database.g.dart` e ficheiro gerado pelo Drift.

## Troubleshooting rapido

- `flutter` nao encontrado: confirmar instalacao e PATH.
- `adb` nao encontrado: instalar Android Platform-Tools.
- emulador nao arranca: validar nome do emulador no `run_aluno.ps1`.
- erro de deps: executar `flutter pub get` no modulo `aluno`.
