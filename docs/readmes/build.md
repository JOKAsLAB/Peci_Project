# Build (Artefactos Gerados)

A pasta `build` guarda saidas geradas por compilacao, testes e ferramentas.

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

## Para que serve

- Armazenar artefactos temporarios de build.
- Apoiar execucoes locais de ferramentas (Flutter, web bundlers, testes).

## A pasta build e precisa?

- Nao como codigo-fonte.
- E util durante execucao local, mas pode ser apagada e regenerada.

## Como interpretar esta pasta

- conteudo de `build` nao representa implementacao funcional,
- conteudo e derivado de codigo em `src/lib/app` e configs de tooling,
- diferencas nesta pasta tendem a ser ruido operacional.

## Regras praticas

- Nao tratar `build` como fonte de verdade.
- Evitar versionar artefactos de build no repositorio.
- Limpar periodicamente artefactos para manter o workspace limpo.

## Artefactos relacionados (fora desta pasta)

- `admin_docente/dist`
- `admin_docente/.vite`
- `aluno/build`
- `aluno/.dart_tool`

## Limpeza recomendada

```powershell
.\scripts\test\clean_test_artifacts.ps1
```

Com limpeza incluindo artefactos mobile:

```powershell
.\scripts\test\clean_test_artifacts.ps1 -IncludeAlunoArtifacts
```

## Observacao

- Podem existir pastas `build/` em mais de um modulo (ex.: mobile e raiz do projeto).
- Todas seguem o mesmo principio: output gerado, nao implementacao manual.
