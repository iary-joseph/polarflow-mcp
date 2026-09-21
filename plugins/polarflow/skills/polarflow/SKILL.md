---
name: polarflow
description: Pilote PolarFlow Studio via le serveur MCP local (outils pf_*). À utiliser pour ouvrir un pipeline fichier, obtenir les schémas, prévisualiser des données, tester et appliquer du code python_column, générer le script ou le notebook exportable. À utiliser aussi quand les outils pf_* sont absents, pour activer le MCP PolarFlow dans Claude Code ou Codex.
---

# PolarFlow (MCP)

PolarFlow Studio est une application Windows d'analyse de données (moteur Polars lazy) qui construit des pipelines sous forme de graphe. Ce skill donne accès à son **moteur local** via le serveur MCP `pf_*` : schémas réels, aperçus de données, test de code Python et application contrôlée sur le fichier pipeline.

## 1. Vérifier l'accès — toujours en premier

Appelle `pf_status`.

| Résultat | Action |
|---|---|
| L'outil `pf_status` n'existe pas | Le MCP n'est pas activé → §2 |
| `engine.available = false` | PolarFlow Studio n'est pas lancé : demande à l'utilisateur de lancer l'application, puis rappelle `pf_status` |
| `engine.available = true` | Prêt → §3 |

## 2. Activer le MCP PolarFlow (outils `pf_*` absents)

Prérequis : **PolarFlow Studio est installé** sur le poste. Le MCP réutilise son binaire, il n'y a rien à télécharger.

### Claude Code (recommandé : plugin marketplace)

```
/plugin marketplace add iary-joseph/polarflow-mcp
/plugin install polarflow@polarflow-mcp
```

Puis `/reload-plugins` (ou redémarrer Claude Code). Les outils `pf_*` et ce skill s'activent ensemble.

### Codex

```
codex mcp add polarflow -- "<chemin>\polarflow-engine.exe" --mcp
```

Si `codex` n'est pas dans le PATH, configure `~/.codex/config.toml` :

```toml
[mcp_servers.polarflow]
command = 'C:\Users\<utilisateur>\AppData\Local\Programs\PolarFlow Studio\polarflow-engine.exe'
args = ["--mcp"]
startup_timeout_sec = 30
tool_timeout_sec = 150
default_tools_approval_mode = "writes"
```

### Quelle que soit la plateforme (script)

Depuis un clone du dépôt `iary-joseph/polarflow-mcp` :

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\polarflow\scripts\setup-mcp.ps1
```

Le script détecte le moteur (variable `POLARFLOW_ENGINE_EXE`, chemin par défaut, puis registre `HKCU\Software\polarflow\PolarFlow Studio`) et configure Claude Code et/ou Codex s'ils sont présents.

### Chemin du moteur

Pour le retrouver toi-même :

```powershell
(Get-ItemProperty 'HKCU:\Software\polarflow\PolarFlow Studio').InstallDir + 'polarflow-engine.exe'
```

Après activation : redémarrer le client (un serveur MCP ne se recharge pas à chaud), puis refaire `pf_status`. Si l'installation est impossible (Studio absent), dis-le clairement à l'utilisateur et n'invente pas de configuration.

## 3. Utiliser le MCP

1. **Ouvrir** : `pf_open_pipeline(pipeline_path="C:\projet\pipeline.json", project_dir="C:\projet")` → `document_ref`.
   - Chemins **absolus** obligatoires.
   - `project_dir` est obligatoire si le pipeline contient des chemins relatifs (c'est le dossier projet PolarFlow, pas forcément le dossier du fichier).
2. **Comprendre** : `pf_companion_context(document_ref)` d'abord (dossier complet en un appel, mode schéma, gratuit), puis `pf_schema(document_ref, node_id?)` si besoin et `pf_node_catalog()` (types + recettes éprouvées par type). `pf_help(query="...")` répond aux questions produit (« comment faire un unpivot ? »).
3. **Observer** : `pf_preview(document_ref, node_id, limit<=50)` — exécute le pipeline jusqu'au nœud.
4. **Diagnostiquer** (sans écrire) : `pf_profile(document_ref, node_id)` (statistiques), `pf_quality(document_ref)` (écarts aux règles), `pf_verify_pipeline(document_ref)` (bilan structurel, jamais d'erreur : cassé = `healthy=false`).
5. **Modifier du code `python_column`** :
   - `pf_validate_python_column(document_ref, node_id, code, execution_mode?)` → aperçu + schéma observé + `validation_id` (15 min, usage unique).
   - `pf_apply_python_column_code(validation_id, accept_contract=true)` → réécrit le fichier avec **exactement** le code testé.
   - Même discipline pour `python_reader` : `pf_validate_python_reader` (pipeline jetable, schéma observé) puis `pf_apply_python_reader_code` (`output_schema`, jamais de contrat).
6. **Retoucher le graphe** : `pf_validate_pipeline_patch(document_ref, groups)` → proposition (5 groupes, 10 ops, code Python exclu), puis `pf_apply_pipeline_patch(validation_id, selected_group_ids?)` (tout ou partie, garde SHA-256). Pour un dossier : `pf_scan_pipelines(root)` puis une boucle validate → apply par fichier.
7. **Exporter** : `pf_codegen(document_ref, save_to="C:\projet\export\pipeline.py")` (ou `format="notebook"` avec un chemin `.ipynb`).

## Travailler sur le document ouvert (live)

Si Studio partage son canvas (`pf_live_status` → `live_ref`, sinon : demander à
l'utilisateur d'activer « Partager » dans le panneau Assistant externe) :

1. Tous les outils de lecture/test ci-dessus acceptent `live_*` au lieu de `document_ref`.
2. `pf_propose_patch(live_ref, groups)` dépose une retouche (même discipline que le patch fichier, code Python exclu) ; l'utilisateur l'applique en 1 clic. Scène changée = proposition périmée. Pour du code : tester via `pf_validate_python_column` sur le `live_ref`, puis `pf_propose_python_column_code(live_ref, validation_id)` — l'utilisateur applique en 1 clic (re-test possible dans l'inspecteur).
3. `pf_run_plan(document_ref)` puis `pf_run_start(run_token, confirm=true)` : sur document live, l'utilisateur doit en plus cliquer « Autoriser le prochain run » (le plan reste valide ; avec `live_ref`, le plan se construit depuis le snapshot, pas depuis un pipeline fourni) ; sur fichier, la confirmation `confirm=true` suffit et la réponse le rappelle. Relire les écrasements (`exists`/`overwrite`) et les règles `block`/`reject` nommées avant de confirmer. `pf_run_cancel()` annule au mieux (points sûrs, sorties partielles à vérifier). Ne jamais appliquer un reçu live au fichier (`live_read_only`).

Détail des outils et des erreurs : `references/tools.md` et `references/troubleshooting.md`.

## 4. Règles non négociables

- **Ne jamais éditer le fichier pipeline à la main** pendant une session MCP : les modifications passent par le MCP (gardes de révision), sinon l'utilisateur perd le bénéfice des contrôles.
- **Toujours validate → apply** (code comme graphe). N'applique jamais ce qui n'a pas passé la validation, et n'applique pas autre chose que le contenu testé.
- **Le code testé s'exécute localement** : préviens l'utilisateur avant `pf_preview` / `pf_validate_python_column` / `pf_validate_python_reader` / `pf_profile` / `pf_quality` (approbation), et n'enchaîne pas de retry automatique.
- **Aucune exécution complète** : `pf_run` n'existe pas ; le lancement complet du pipeline reste dans l'interface Studio.
- Après une erreur `stale_document` : le fichier a changé, refais un test avant toute application.
- Si le moteur n'est pas lancé, arrête-toi et demande à l'utilisateur d'ouvrir Studio : n'essaie pas de lancer l'application toi-même.
