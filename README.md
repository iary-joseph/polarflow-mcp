# PolarFlow MCP

Plugin et skill pour brancher **PolarFlow Studio** sur un assistant IA de développement (Claude Code, Codex) via MCP.

L'assistant devient le modèle ; PolarFlow fournit les **faits** (schémas réels, aperçus de données) et l'**exécution locale** : tester du code Python sur un pipeline, l'appliquer de façon contrôlée, générer le script de production. **Aucune clé API, aucun appel LLM côté PolarFlow.**

```text
Claude Code / Codex
        │  MCP stdio
        ▼
polarflow-engine.exe --mcp      (binaire déjà installé par PolarFlow Studio)
        │  HTTP 127.0.0.1
        ▼
moteur PolarFlow (Studio lancé)
```

## Prérequis

- **PolarFlow Studio installé** sur le poste (le MCP réutilise son binaire — rien à télécharger).
- **PolarFlow Studio lancé** pour les outils moteur (`pf_schema`, `pf_preview`, `pf_validate_python_column`, `pf_codegen`) ; les outils fichier fonctionnent sans.
- Windows.

## Installation rapide

### Claude Code

```
/plugin marketplace add iary-joseph/polarflow-mcp
/plugin install polarflow@polarflow-mcp
```

`/reload-plugins`, puis demandez « appelle pf_status ».

### Codex

```powershell
codex mcp add polarflow -- "$env:LOCALAPPDATA\Programs\PolarFlow Studio\polarflow-engine.exe" --mcp
```

Configuration manuelle et installation du skill : voir [`INSTALL.md`](INSTALL.md).

### Script (tous clients détectés)

Depuis un clone du dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\polarflow\scripts\setup-mcp.ps1
```

Le script détecte le moteur (variable `POLARFLOW_ENGINE_EXE`, chemin d'installation par défaut, puis registre) et configure Claude Code et/ou Codex s'ils sont présents.

## Ce que ça permet

- « Ouvre mon pipeline ventes et donne-moi le schéma de chaque étape. »
- « Écris une colonne `marge` en Python, teste-la sur des données réelles, puis applique-la. »
- « Génère le script de production / le notebook à cet endroit. »

Le code testé s'exécute **localement** (comme un test lancé depuis l'interface) : les clients demandent une approbation pour les outils qui exécutent ou écrivent. Ce n'est pas une sandbox.

## Contenu du dépôt

| Chemin | Rôle |
|---|---|
| `plugins/polarflow/skills/polarflow/SKILL.md` | Skill : installer/activer le MCP + workflow d'utilisation |
| `plugins/polarflow/scripts/polarflow-mcp.cmd` | Lanceur stdio : résout `polarflow-engine.exe` installé |
| `plugins/polarflow/scripts/setup-mcp.ps1` | Configuration idempotente Claude Code / Codex |
| `.claude-plugin/marketplace.json` | Marketplace Claude Code |
| `.agents/plugins/marketplace.json` | Marketplace Codex |
| `INSTALL.md` | Installation détaillée par client |
| `plugins/polarflow/skills/polarflow/references/` | Outils et dépannage |

## Sécurité

- Le serveur MCP ne fait aucun appel réseau sortant autre que `127.0.0.1` (le moteur local).
- Aucune clé, aucun secret dans les arguments ou la configuration.
- L'application au fichier pipeline est liée à un test réussi : le code appliqué est exactement le code testé, et un fichier modifié entre-temps est refusé.
- Les données lues (chemins, schémas, aperçus, code) peuvent être envoyées au fournisseur de l'assistant utilisé — politique à cadrer côté équipe.

## Licence

MIT — voir [`LICENSE`](LICENSE).
