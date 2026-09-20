# Installation détaillée

## Prérequis (tous les clients)

1. PolarFlow Studio installé (installation par utilisateur par défaut).
2. Vérifier le binaire du moteur :

   ```powershell
   Test-Path "$env:LOCALAPPDATA\Programs\PolarFlow Studio\polarflow-engine.exe"
   # Si absent (autre dossier d'installation) :
   (Get-ItemProperty 'HKCU:\Software\polarflow\PolarFlow Studio').InstallDir + 'polarflow-engine.exe'
   ```

3. Pour les outils moteur, **PolarFlow Studio doit être lancé** : le serveur MCP le découvre tout seul (pas de port à configurer).

---

## Claude Code

### Méthode recommandée : plugin marketplace

```
/plugin marketplace add iary-joseph/polarflow-mcp
/plugin install polarflow@polarflow-mcp
```

Puis `/reload-plugins` (ou redémarrer Claude Code). Le plugin installe **le skill et le serveur MCP** ; le lanceur résout le moteur installé (`POLARFLOW_ENGINE_EXE` → chemin par défaut → registre).

Vérification : `/mcp` doit montrer `polarflow` connecté ; demandez « appelle pf_status ».

### Méthode manuelle

```powershell
claude mcp add --transport stdio --scope user polarflow -- "$env:LOCALAPPDATA\Programs\PolarFlow Studio\polarflow-engine.exe" --mcp
```

Sans le binaire dans le PATH, la configuration générique dans `~/.claude.json` ou un `.mcp.json` de projet :

```json
{
  "mcpServers": {
    "polarflow": {
      "command": "${LOCALAPPDATA}\\Programs\\PolarFlow Studio\\polarflow-engine.exe",
      "args": ["--mcp"],
      "timeout": 180000
    }
  }
}
```

`timeout` (ms) couvre les tests `python_column` jusqu'à 120 s.

### Installer le skill sans plugin

Copiez `plugins/polarflow/skills/polarflow/` dans `~/.claude/skills/polarflow/` (ou `<projet>/.claude/skills/polarflow/`).

### Désinstallation

```
/plugin uninstall polarflow@polarflow-mcp
# ou
claude mcp remove polarflow
```

---

## Codex

### Ajouter le serveur MCP

```powershell
codex mcp add polarflow -- "$env:LOCALAPPDATA\Programs\PolarFlow Studio\polarflow-engine.exe" --mcp
```

Ou manuellement dans `~/.codex/config.toml` (chemin littéral, Codex n'expanse pas les variables) :

```toml
[mcp_servers.polarflow]
command = 'C:\Users\<utilisateur>\AppData\Local\Programs\PolarFlow Studio\polarflow-engine.exe'
args = ["--mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 150
default_tools_approval_mode = "writes"
```

- `startup_timeout_sec = 30` : le binaire auto-extractible met ~5 s à démarrer (défaut Codex : 10 s).
- `tool_timeout_sec = 150` : couvre les 120 s maximales d'un test moteur (défaut : 60 s).
- `default_tools_approval_mode = "writes"` : Codex demande confirmation pour les outils non read-only (`pf_preview`, `pf_validate_python_column`, `pf_apply_python_column_code`, `pf_codegen`).

Redémarrer Codex, puis `codex mcp list` ; demandez « appelle pf_status ».

### Installer le skill

Options (au choix) :

1. `$skill-installer` en lui indiquant ce dépôt ;
2. copier `plugins/polarflow/skills/polarflow/` dans `~/.agents/skills/polarflow/` ;
3. marketplace Codex (plugin + skill) :

   ```powershell
   codex plugin marketplace add iary-joseph/polarflow-mcp
   ```

Le plugin Codex distribue le **skill** ; le serveur MCP reste ajouté par `codex mcp add` (la configuration MCP embarquée n'est pas encore validée sur toutes les versions de Codex).

---

## Autre client MCP (snippet générique)

Tout client qui lance un serveur MCP stdio accepte ce bloc :

```json
{
  "mcpServers": {
    "polarflow": {
      "command": "C:\\Users\\<utilisateur>\\AppData\\Local\\Programs\\PolarFlow Studio\\polarflow-engine.exe",
      "args": ["--mcp"]
    }
  }
}
```

Le serveur parle MCP 2026-07-28 et les révisions antérieures (clients legacy inclus). Transport **stdio uniquement** (pas de HTTP) ; Windows uniquement pour le binaire.

---

## Script de configuration

Depuis un clone de ce dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\polarflow\scripts\setup-mcp.ps1
```

Le script :

1. résout le moteur (`POLARFLOW_ENGINE_EXE` → `%LOCALAPPDATA%\Programs\PolarFlow Studio\polarflow-engine.exe` → registre `HKCU\Software\polarflow\PolarFlow Studio`) ;
2. ajoute le serveur à Claude Code et/ou Codex s'ils sont dans le PATH (idempotent) ;
3. rappelle de redémarrer le client et de lancer Studio.

---

## Dépannage

Voir `plugins/polarflow/skills/polarflow/references/troubleshooting.md`.
Journal du serveur MCP : `%APPDATA%\com.polarflow.studio\logs\polarflow-mcp.log`.
