[CmdletBinding()]
param(
    [string]$SourceUi,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

$inkscapeUiDirectory = Join-Path $env:APPDATA 'inkscape\ui'
$destination = Join-Path $inkscapeUiDirectory 'toolbar-tool.ui'
$stateFile = Join-Path $inkscapeUiDirectory 'inkstitch-quick-access.json'

if ($Remove) {
    if (-not (Test-Path -LiteralPath $stateFile)) {
        Write-Host 'A barra de acesso rápido do Ink/Stitch não está registrada.'
        exit 0
    }

    $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    if ($state.backup -and (Test-Path -LiteralPath $state.backup)) {
        Copy-Item -LiteralPath $state.backup -Destination $destination -Force
        Write-Host "Interface anterior restaurada: $destination"
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
$source = if (-not $createdDestination) { $destination } else { $SourceUi }

if (-not $source -or -not (Test-Path -LiteralPath $source)) {
    throw 'Informe -SourceUi com o caminho do toolbar-tool.ui original do Inkscape.'
}

[xml]$document = Get-Content -Raw -LiteralPath $source
if ($document.SelectSingleNode("//*[@id='inkstitch-quick-access']")) {
    Write-Host "A barra do Ink/Stitch já está instalada: $destination"
    exit 0
}

$toolbar = $document.SelectSingleNode("//object[@class='GtkBox'][property[@name='name' and text()='tool-toolbar']]")
if (-not $toolbar) {
    throw 'O toolbar-tool.ui não contém a barra vertical esperada do Inkscape 1.4.'
}

$fragment = $document.CreateDocumentFragment()
$fragment.InnerXml = @'
<child>
  <object class="GtkSeparator" id="inkstitch-quick-access-separator">
    <property name="visible">True</property>
  </object>
  <packing><property name="fill">False</property></packing>
</child>
<child>
  <object class="GtkFlowBox" id="inkstitch-quick-access">
    <property name="homogeneous">True</property>
    <property name="visible">True</property>
    <property name="halign">start</property>
    <property name="valign">start</property>
    <property name="max-children-per-line">2</property>
    <style><class name="tight-flowbox"/></style>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-params">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Parâmetros</property>
        <property name="action-name">app.org.inkstitch.params</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">dialog-object-properties</property></object></child>
      </object>
    </child></object></child>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-simulator">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Simulador</property>
        <property name="action-name">app.org.inkstitch.simulator</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">media-playback-start</property></object></child>
      </object>
    </child></object></child>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-lettering">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Letras</property>
        <property name="action-name">app.org.inkstitch.lettering</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">draw-text</property></object></child>
      </object>
    </child></object></child>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-commands">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Anexar comandos</property>
        <property name="action-name">app.org.inkstitch.commands</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">draw-connector</property></object></child>
      </object>
    </child></object></child>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-troubleshoot">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Solução de problemas</property>
        <property name="action-name">app.org.inkstitch.troubleshoot</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">dialog-warning</property></object></child>
      </object>
    </child></object></child>
    <child><object class="GtkFlowBoxChild"><property name="visible">True</property><child>
      <object class="GtkButton" id="inkstitch-quick-preferences">
        <property name="visible">True</property><property name="focus-on-click">False</property>
        <property name="tooltip-text">Ink/Stitch: Preferências</property>
        <property name="action-name">app.org.inkstitch.preferences</property><property name="relief">none</property>
        <child><object class="GtkImage"><property name="visible">True</property><property name="icon-name">preferences-system</property></object></child>
      </object>
    </child></object></child>
  </object>
  <packing><property name="fill">False</property></packing>
</child>
'@

$toolbar.AppendChild($fragment) | Out-Null

$backup = $null
if (-not $createdDestination) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = Join-Path $inkscapeUiDirectory "toolbar-tool.ui.pre-inkstitch-$timestamp.bak"
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

Write-Host "Barra de acesso rápido instalada: $destination"
Write-Host 'Reinicie o Inkscape para os seis botões aparecerem na barra lateral esquerda.'
