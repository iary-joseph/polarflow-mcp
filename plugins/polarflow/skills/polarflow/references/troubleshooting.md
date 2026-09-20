# Dépannage MCP PolarFlow

## Vérifications de base

1. `pf_status` → `engine.available`.
2. PolarFlow Studio est-il lancé ? (les outils moteur en ont besoin)
3. Le binaire existe-t-il ?
   ```powershell
   Test-Path "$env:LOCALAPPDATA\Programs\PolarFlow Studio\polarflow-engine.exe"
   ```
   Sinon : `(Get-ItemProperty 'HKCU:\Software\polarflow\PolarFlow Studio').InstallDir`
4. Journal MCP : `%APPDATA%\com.polarflow.studio\logs\polarflow-mcp.log`

## Par code d'erreur

| Code | Cause | Action |
|---|---|---|
| `engine_unavailable` | Studio non lancé, ou moteur sur un autre port | Lancer/relancer PolarFlow Studio, puis réessayer |
| `engine_incompatible` | Le moteur qui tourne vient d'une autre version (mise à jour pendant la session) | Redémarrer PolarFlow Studio |
| `document_not_found` | Handle expiré (1 h), fichier déplacé/supprimé, nœud inexistant | Rouvrir avec `pf_open_pipeline` |
| `invalid_pipeline` | JSON invalide, nœud inconnu, erreur moteur 4xx | Lire `message` et `diagnostic`, corriger le pipeline ou le code |
| `invalid_code` | Syntaxe Python ou fonction `transform` manquante/mauvaise arité | Corriger avant de retester |
| `stale_document` | Le fichier a changé entre le test et l'application | Refaire `pf_validate_python_column` |
| `validation_expired` | Reçu de plus de 15 min | Refaire un test |
| `validation_consumed` | Reçu déjà appliqué (usage unique) | Refaire un test |
| `contract_not_supported` | `accept_contract=true` hors mode `dataframe` | Rappeler avec `accept_contract=false` |
| `unsafe_path` | Chemin relatif, lien symbolique, extension inattendue, dossier absent | Fournir un chemin absolu valide |
| `output_exists` | Le fichier `save_to` existe déjà | Confirmer puis `overwrite=true` |
| `output_too_large` | Pipeline > 5 Mio, fichier grossi depuis l'ouverture | Réduire/export régénéré |
| `io_error` | Droits ou fichier verrouillé | Fermer le logiciel qui verrouille, vérifier les droits |
| `engine_error` | Erreur moteur 5xx ou réponse illisible | Relancer Studio puis réessayer |

## Cas particuliers

- **Le client ne voit pas les outils `pf_*`** : après une installation de serveur MCP, il faut redémarrer le client (`/reload-plugins` dans Claude Code). Vérifier `/mcp` (Claude Code) ou `codex mcp list`.
- **Le premier lancement du serveur est lent (~5 s)** : le binaire est un exécutable auto-extractible. Augmenter `startup_timeout_sec` (Codex) ou `MCP_TIMEOUT` (Claude Code) si besoin.
- **Test long coupé par le client** : `tool_timeout_sec = 150` (Codex) ou `"timeout": 180000` (Claude Code `.mcp.json`) couvrent les 120 s maximales du moteur.
- **Deux clients ouverts en parallèle** : les gardes sont par processus ; éviter deux tests simultanés sur le même pipeline.
- **Fichier sur un partage réseau (UNC)** : supporté (`\\serveur\partage\...`), y compris comme `project_dir`.
