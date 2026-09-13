[CmdletBinding()]
param(
    [string]$SourceGlade,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$inkscapeUiDirectory = Join-Path $env:APPDATA 'inkscape\ui'
$destination = Join-Path $inkscapeUiDirectory 'dialog-objects.glade'
$stateFile = Join-Path $inkscapeUiDirectory 'inkstitch-dock-launcher.json'

if ($Remove) {
    if (-not (Test-Path -LiteralPath $stateFile)) {
        Write-Host 'O painel textual do Ink/Stitch não está registrado.'
        exit 0
    }

    $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    if ($state.backup -and (Test-Path -LiteralPath $state.backup)) {
        Copy-Item -LiteralPath $state.backup -Destination $destination -Force
        Write-Host "Painel anterior restaurado: $destination"
    }
    elseif ($state.createdDestination -and (Test-Path -LiteralPath $destination)) {
        Remove-Item -LiteralPath $destination -Force
        Write-Host "Personalização removida: $destination"
    }

    Remove-Item -LiteralPath $stateFile -Force
    Write-Host 'Reinicie o Inkscape para concluir.'
    exit 0
}

New-Item -ItemType Directory -Path $inkscapeUiDirectory -Force | Out-Null

$createdDestination = -not (Test-Path -LiteralPath $destination)
$source = if (-not $createdDestination) { $destination } else { $SourceGlade }

if (-not $source -or -not (Test-Path -LiteralPath $source)) {
    throw 'Informe -SourceGlade com o caminho do dialog-objects.glade original do Inkscape.'
}

[xml]$document = Get-Content -Raw -LiteralPath $source
if ($document.SelectSingleNode("//*[@id='inkstitch-dock-launcher']")) {
    Write-Host "O painel textual do Ink/Stitch já está instalado: $destination"
    exit 0
}

$header = $document.SelectSingleNode("//object[@class='GtkBox' and @id='header']")
if (-not $header) {
    throw 'O dialog-objects.glade não contém o cabeçalho esperado do Inkscape 1.4.'
}

$orientation = $header.SelectSingleNode("./property[@name='orientation']")
if (-not $orientation) {
    $orientation = $document.CreateElement('property')
    $orientation.SetAttribute('name', 'orientation')
    $orientation.InnerText = 'vertical'
    $header.InsertBefore($orientation, $header.SelectSingleNode('./child[1]')) | Out-Null
}
else {
    $orientation.InnerText = 'vertical'
}

$controlsChild = $document.CreateElement('child')
$controls = $document.CreateElement('object')
$controls.SetAttribute('class', 'GtkBox')
$controls.SetAttribute('id', 'inkstitch-dock-original-controls')
$controlsChild.AppendChild($controls) | Out-Null

$visible = $document.CreateElement('property')
$visible.SetAttribute('name', 'visible')
$visible.InnerText = 'True'
$controls.AppendChild($visible) | Out-Null

$existingChildren = @($header.SelectNodes('./child'))
foreach ($child in $existingChildren) {
    $header.RemoveChild($child) | Out-Null
    $controls.AppendChild($child) | Out-Null
}
$header.AppendChild($controlsChild) | Out-Null

$fragment = $document.CreateDocumentFragment()
$fragment.InnerXml = @'
<child>
  <object class="GtkExpander" id="inkstitch-dock-launcher">
    <property name="visible">True</property>
    <property name="can-focus">True</property>
    <property name="expanded">True</property>
    <property name="label">Ink/Stitch</property>
    <child>
      <object class="GtkGrid" id="inkstitch-dock-grid">
        <property name="visible">True</property>
        <property name="hexpand">True</property>
        <property name="margin-start">6</property>
        <property name="margin-end">6</property>
        <property name="margin-top">4</property>
        <property name="margin-bottom">6</property>
        <property name="column-spacing">6</property>
        <property name="row-spacing">4</property>
        <property name="column-homogeneous">True</property>
        <child>
          <object class="GtkButton" id="inkstitch-dock-params"><property name="label">Parâmetros</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.params</property></object>
          <packing><property name="left-attach">0</property><property name="top-attach">0</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-simulator"><property name="label">Simulador</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.simulator</property></object>
          <packing><property name="left-attach">1</property><property name="top-attach">0</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-lettering"><property name="label">Letras</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.lettering</property></object>
          <packing><property name="left-attach">0</property><property name="top-attach">1</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-commands"><property name="label">Anexar comandos</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.commands</property></object>
          <packing><property name="left-attach">1</property><property name="top-attach">1</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-preview"><property name="label">Pré-visualizar pontos</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.stitch-plan-preview</property></object>
          <packing><property name="left-attach">0</property><property name="top-attach">2</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-thread-list"><property name="label">Lista de linhas</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.thread-list</property></object>
          <packing><property name="left-attach">1</property><property name="top-attach">2</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-troubleshoot"><property name="label">Solução de problemas</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.troubleshoot</property></object>
          <packing><property name="left-attach">0</property><property name="top-attach">3</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-cleanup"><property name="label">Limpar documento</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.cleanup</property></object>
          <packing><property name="left-attach">1</property><property name="top-attach">3</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-preferences"><property name="label">Preferências</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.preferences</property></object>
          <packing><property name="left-attach">0</property><property name="top-attach">4</property></packing>
        </child>
        <child>
          <object class="GtkButton" id="inkstitch-dock-about"><property name="label">Sobre o Ink/Stitch</property><property name="visible">True</property><property name="hexpand">True</property><property name="action-name">app.org.inkstitch.about</property></object>
          <packing><property name="left-attach">1</property><property name="top-attach">4</property></packing>
        </child>
      </object>
    </child>
  </object>
</child>
'@
$header.AppendChild($fragment) | Out-Null

$backup = $null
if (-not $createdDestination) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $inkscapeUiDirectory "dialog-objects.glade.pre-inkstitch-$timestamp.bak"
    Copy-Item -LiteralPath $destination -Destination $backup
}

$settings = [System.Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [System.Text.UTF8Encoding]::new($false)
$writer = [System.Xml.XmlWriter]::Create($destination, $settings)
try {
    $document.Save($writer)
}
finally {
    $writer.Dispose()
}

[pscustomobject]@{
    backup = $backup
    createdDestination = $createdDestination
    installedAt = (Get-Date).ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8NoBOM

Write-Host "Painel textual instalado: $destination"
Write-Host 'Reinicie o Inkscape e abra Camadas e Objetos para visualizar o bloco Ink/Stitch.'
