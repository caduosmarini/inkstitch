# Fork Ink/Stitch: preenchimento de lacunas e pt-BR

## Estado desta versão

- Base estável: `v3.3.0` (`b0edd9631`).
- Branch: `fix/gap-fill-clipping-v3.3.0`.
- Correção geométrica: `ef7f14fb4`.
- Catálogo pt-BR: `cff62731d`.
- Versão instalada: `v3.3.0-gapfix-cff62731d (windows-x86_64)`.
- Fork: <https://github.com/caduosmarini/inkstitch>.
- Upstream: <https://github.com/inkstitch/inkstitch>.

A correção recorta cada fileira adicional de `Gap Filling` pela forma de
preenchimento já ajustada. Quando o recorte produz vários segmentos, somente o
componente alcançável sem atravessar contorno ou buraco é usado. As fileiras são
confirmadas em pares e somente quando o retorno à sequência original também
permanece dentro da forma.

O vetor SVG original não é modificado. Expansão e compensação de repuxo são
preservadas porque o recorte recebe a mesma geometria final utilizada pelo
Tatami.

## Validação registrada em 2026-09-13

- Suíte completa: `52 passed`.
- Catálogo: `2211` entradas, `2211` traduzidas, `0` não traduzidas, `0` fuzzy e
  `0` erros de parâmetros, plurais ou tags.
- Caso público da issue 3278, sem cache:

| Gap Filling | v3.3.0 | Corrigido | Resultado geométrico |
| --- | ---: | ---: | --- |
| 0 | 2098 pontos | 2098 pontos | VP3 idêntico |
| 2 | 2107 pontos | 2098 pontos | fileira externa indevida removida |
| 4 | 2116 pontos | 2098 pontos | duas fileiras externas indevidas removidas |

Nos três VP3 corrigidos: `45,2 x 47,4 mm`, um bloco de cor e uma linha. O smoke
test do pacote instalado também exportou VP3 com sucesso e sem saída de erro.

Os testes unitários adicionais cobrem valor zero, curva, concavidade, buraco e
seleção de componente alcançável. Ainda são necessários:

1. abrir `Parâmetros` e o simulador no Inkscape real;
2. validar o SVG específico do usuário quando ele estiver disponível;
3. bordar retalhos com `Gap Filling` 0, 2 e 4 na Singer SE9185.

O simulador e o VP3 validam software e geometria, não o comportamento físico do
tecido.

## Catálogo pt-BR

A fonte mantida é `translations/messages_pt_BR.po`. O build gera:

- `bin/locales/pt_BR/LC_MESSAGES/inkstitch.mo`, usado pelas janelas internas;
- `inx/locale/pt/LC_MESSAGES/inkstitch.mo`, usado pelos menus do Inkscape.

Validar antes de compilar:

```powershell
uv run --with Babel python bin/validate-pt-br-catalog translations/messages_pt_BR.po
```

Compilar isoladamente no Windows:

```powershell
New-Item -ItemType Directory -Force locales/pt_BR/LC_MESSAGES
uv run --with Babel pybabel compile `
  -i translations/messages_pt_BR.po `
  -o locales/pt_BR/LC_MESSAGES/inkstitch.mo
```

Não considerar o catálogo concluído apenas porque compila. Revisar linguagem,
atalhos, URLs, plurais e textos longos diretamente nas janelas do Ink/Stitch.

## Atualizar a partir do upstream

Manter `main` como espelho do projeto oficial:

```powershell
git switch main
git fetch upstream --prune --tags
git merge --ff-only upstream/main
git push origin main
```

Testar uma nova versão estável sem alterar a instalação ativa:

```powershell
git switch -c test/upstream-vX.Y.Z vX.Y.Z
git cherry-pick ef7f14fb4
git cherry-pick cff62731d
```

Se a correção já tiver entrado oficialmente, não aplicar `ef7f14fb4`; executar os
testes contra a implementação upstream. Se houver conflito no catálogo, manter
os novos `msgid` do upstream, mesclar as traduções pt-BR, revisar todas as
entradas novas ou `fuzzy` e executar o validador.

Depois da integração:

```powershell
uv run pytest -q
uv run --with Babel python bin/validate-pt-br-catalog translations/messages_pt_BR.po
```

## Build Windows local

O workflow oficial usa Python 3.11, PyInstaller, Git for Windows SDK, `make` e
`gettext`. Nesta máquina, `make` e `msgfmt` não estavam disponíveis; o build
isolado validado foi gerado com o mesmo Python 3.11 e PyInstaller 6.20:

```powershell
uv run python -m PyInstaller --noconfirm --clean `
  --contents-directory . --log-level INFO `
  --icon images/inkstitch/win/inkstitch.ico `
  --windowed --name inkstitch inkstitch.py
```

Antes de instalar, montar uma cópia completa da versão estável, sobrepor o
conteúdo de `dist/inkstitch` em `inkstitch/bin`, adicionar os dois catálogos e
identificar `VERSION` com a versão-base e o commit.

Nunca substituir a extensão com o Inkscape ou `inkstitch.exe` em execução. Não
encerrar o Inkscape à força: salvar ou fechar os documentos normalmente.

## Instalação atual e restauração

Instalação ativa:

```text
C:\Users\caduo\AppData\Roaming\inkscape\extensions\inkstitch
```

Backup completo anterior:

```text
C:\Users\caduo\AppData\Roaming\inkscape\inkstitch-backups\inkstitch-before-gapfix-20260913-1857
```

Para restaurar, feche normalmente o Inkscape e confirme que não há
`inkstitch.exe` em execução. Mova a instalação corrigida para uma pasta de
retenção fora de `extensions` e copie o backup para o caminho ativo:

```powershell
$active = 'C:\Users\caduo\AppData\Roaming\inkscape\extensions\inkstitch'
$backup = 'C:\Users\caduo\AppData\Roaming\inkscape\inkstitch-backups\inkstitch-before-gapfix-20260913-1857'
$retained = 'C:\Users\caduo\AppData\Roaming\inkscape\inkstitch-backups\inkstitch-gapfix-retained'
Move-Item -LiteralPath $active -Destination $retained
Copy-Item -LiteralPath $backup -Destination $active -Recurse
```

Não há atualização automática configurada.

### Barra lateral de acesso rápido no Inkscape 1.4 para Windows

O Inkscape não permite que uma extensão INX registre um painel acoplável como o
Rastrear bitmap. Para evitar a navegação repetida pelo menu, este fork inclui uma
personalização reversível da barra lateral nativa, com botões para Parâmetros,
Simulador, Letras, Anexar comandos, Solução de problemas e Preferências.

Com o Inkscape fechado, execute:

```powershell
powershell -ExecutionPolicy Bypass -File installer_scripts/windows/install-quick-access-toolbar.ps1 `
  -SourceUi "C:\caminho\do\Inkscape\share\inkscape\ui\toolbar-tool.ui"
```

O instalador preserva qualquer `toolbar-tool.ui` personalizado antes de alterá-lo.
Para desfazer:

```powershell
powershell -ExecutionPolicy Bypass -File installer_scripts/windows/install-quick-access-toolbar.ps1 -Remove
```

É necessário reiniciar o Inkscape depois de instalar ou remover a barra.

## Texto técnico para futuro pull request

**Title:** Clip Tatami gap-fill rows to the valid fill geometry

**Summary:**

Tatami gap filling offsets copies of the last row when the stitch path leaves a
section. On curved or holed shapes, the copies and their connectors can extend
outside the fill geometry. This change passes the effective fill shape to the
gap-filling stage, clips every candidate row, selects only a reachable line
component, and commits rows in pairs only when the path can safely return.

**Compatibility and tests:**

- `gap_fill_rows = 0` is unchanged;
- valid overlap rows remain available at section junctions;
- outer contours and holes are not crossed;
- split intersections do not create stitches between disconnected components;
- regression tests cover curves, holes, concavity and the public issue 3278
  sample.

Do not publish this PR until the user explicitly requests it.
