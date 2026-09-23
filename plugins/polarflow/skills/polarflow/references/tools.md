# Outils MCP PolarFlow

Prérequis : **PolarFlow Studio lancé** pour les outils moteur ; les outils fichier fonctionnent sans.
Tous les chemins sont **absolus** (Windows). `project_dir` est obligatoire si le pipeline contient des chemins relatifs.

| Outil | Entrées | Sorties | Exécute du code |
|---|---|---|---|
| `pf_status` | — | `{mcp_version, server_version, engine{available, url, contract_version, polars_version}}` | non |
| `pf_open_pipeline` | `pipeline_path`, `project_dir?` | `{document_ref, revision, pipeline_path, project_dir, summary, expires_in_s}` | non |
| `pf_get_pipeline` | `document_ref` | `{revision, pipeline, truncated}` | non |
| `pf_schema` | `document_ref`, `node_id?` | `{revision, schemas[], truncated, omissions[]}` | non |
| `pf_companion_context` | `document_ref`, `focus_node_ids?` (8 max), `view?` (`summary`/`focused`/`full`) | `{revision, context{revision, overview, details, evidence, coverage, lineage, quality, dataset_contract, used_types}, truncated, omissions}` | non |
| `pf_help` | `topic?`, `query?` | `{results[{id, title, source, excerpt}], truncated, omissions}` (10 max, insensible casse/accents) | non |
| `pf_node_catalog` | — | `{types: {type: {category, data_schema, recipes[{title, data, fixture_kind}]}}, truncated, omissions}` | non |
| `pf_profile` | `document_ref`, `node_id`, `columns?` (100 max), `mode?` (`quick`/`full`) | `{revision, node_id, mode, row_count, columns, truncated, omissions}` | **oui** |
| `pf_quality` | `document_ref`, `node_id?` | `{revision, target, score, results, blocked, warn_only, truncated, omissions}` (100 résultats, messages 500 car.) | **oui** |
| `pf_verify_pipeline` | `document_ref` | `{revision, healthy, anomalies, readers, writers, inline_code, ...}` (jamais d'erreur) | non |
| `pf_preview` | `document_ref`, `node_id`, `limit?` (1..50, défaut 20) | `{revision, columns, rows, truncated, omissions}` | **oui** |
| `pf_validate_python_column` | `document_ref`, `node_id`, `code`, `execution_mode?` (`dataframe`/`batch`/`element`) | `{validation_id, node_id, execution_mode, candidate_sha256, source_revision, observation, preview, delta, duration_ms, expires_in_s}` | **oui** |
| `pf_apply_python_column_code` | `validation_id`, `accept_contract?` (défaut `true`) | `{applied, already_applied, node_id, contract_written, revision}` | non |
| `pf_validate_python_reader` | `document_ref`, `node_id`, `code` | `{validation_id, observed_columns, preview, truncated, omissions, expires_in_s}` | **oui** |
| `pf_apply_python_reader_code` | `validation_id`, `accept_schema?` (défaut `true`) | `{applied, node_id, schema_written, warnings, revision}` | non |
| `pf_validate_pipeline_patch` | `document_ref` (fichier), `groups=[{title, ops:[...]}]` (10 groupes, 20 ops + 50 libellés, code Python exclu) | `{validation_id, status, groups, dropped_groups, warnings, expires_in_s}` | non |
| `pf_apply_pipeline_patch` | `validation_id`, `selected_group_ids?` (`None` = tout) | `{applied, groups_applied, revision}` | non |
| `pf_scan_pipelines` | `root`, `recursive?`, `pattern?` | `{root, files[{path, size_bytes, valid, ...}], truncated, omissions}` (100 max) | non |
| `pf_live_status` | — | `{live_ref, revision, pushed_at, expires_in_s, proposals_pending}` (jamais de contenu) | non |
| `pf_propose_patch` | `live_ref`, `groups` (idem patch fichier) | `{proposal_id, kind: "patch", live_ref, base_revision, groups, dropped_groups, warnings}` | non |
| `pf_propose_python_column_code` | `live_ref`, `validation_id` (test live, scène inchangée, reçu consommé) | `{proposal_id, kind: "code", live_ref, base_revision, node_id, execution_mode, columns}` | non |
| `pf_run_plan` | `document_ref` (fichier ou live ; live = snapshot, pas le fourni) | `{run_token, revision, node_count, edge_count, readers, writers[{node_id, output_path, exists, overwrite}], inline_code, quality_blocks[id], quality_rejects[{id, kind, column}], expires_in_s}` | non |
| `pf_run_start` | `run_token`, `confirm` (`true` exigé) | `{status: completed\|cancelled, revision, writers, outputs, message?, confirmation_note?}` | **oui** |
| `pf_run_cancel` | — | `{cancelled, reason?}` (`no_active_run` si rien ne tourne) | non |
| `pf_codegen` | `document_ref` (fichier), `save_to`, `format?` (`script`/`notebook`), `overwrite?`, `strict?` | `{path, bytes, sha256, format, warnings, syntax_ok, run_contract_present}` | non |

## Format du patch graphe (script → pipeline)

`groups` est une liste de groupes, jamais d'ops à plat : `[{title, ops:[...]}]`
(un groupe = une étape : lecture, transfo + câblage, writer).

- `add_node{id,type,label,data}` : `data` suit le schéma Pydantic du type
  (voir `pf_node_catalog()`). `join` = 2 entrées (ordre = gauche/droite) ;
  lecteurs = 0 entrée ; writers = 1 entrée (`excel_writer` = N).
- `add_edge` / `remove_edge{source,target}` : `remove` uniquement pour
  réaiguiller une connexion existante (ex. insérer un nœud entre deux autres).
- `update_node{id,data}` : champs modifiés seuls (un libellé seul suit la voie
  cosmétique, jusqu'à 50 ops).
- `delete_node{id}` : supprime le nœud et ses flèches, puis recâbler les
  voisins (ex. supprimer un filtre entre A et B = `delete_node` + `add_edge` A→B).
- Code `python_column` / `python_reader` exclu : phase 1 = structure via le
  patch, phase 2 = `pf_validate_python_column` puis apply/propose.
- Sans le code source : `pf_companion_context` puis `pf_schema` puis
  `pf_node_catalog` d'abord, ne jamais inventer de colonne, `output_path`
  demandé tel quel (sinon nœud avec chemin vide). `pf_help(query="patch groups")`
  rappelle ce format.

## Cycle validate → apply

```
pf_validate_python_column(code)
        │  exécute le code sur un aperçu réel (aucune écriture)
        ▼
   validation_id  ──(15 min, usage unique, non forgeable)
        │
        ▼
pf_apply_python_column_code(validation_id, accept_contract=true)
        │  revérifie : fichier inchangé (SHA-256), moteur identique
        ▼
   fichier réécrit avec EXACTEMENT le code testé
```

- `accept_contract=true` (mode `dataframe` seulement) : la sortie observée devient le contrat officiel du nœud (`origin: observed`). Les exécutions suivantes vérifient que la sortie reste conforme.
- `accept_contract=false` : l'ancien **contrat observé** est retiré ; les déclarations manuelles `output_schema`/`dropped_columns` sont conservées.
- En modes `batch`/`element` : `accept_contract=true` est refusé ; les champs de contrat deviennent inutiles et sont purgés.

## Contrat de sortie observé

`pf_validate_python_column` retourne `observation.columns` (colonnes et types encodés exactement) et `observation.reference` (empreintes du contexte de test). En mode `dataframe`, accepter le contrat permet au moteur de détecter immédiatement toute dérive de sortie — recommande `accept_contract=true` sauf demande contraire de l'utilisateur.

## Bornes

| Donnée | Limite |
|---|---|
| Fichier pipeline | 5 Mio |
| Aperçu | 100 colonnes, 50 lignes, cellule 4 000 caractères, enveloppe 256 Kio (octets) |
| Schémas | 200 nœuds, 100 colonnes par nœud |
| Contexte compagnon | 40 Kio, focus 8 nœuds max |
| Catalogue | 40 Kio (types réduits à la catégorie si dépassement) |
| Profil | 100 colonnes |
| Qualité | 100 résultats, messages 500 caractères, enveloppe 256 Kio |
| Scan | 100 fichiers, profondeur 8, validité 5 Mio par fichier |
| Session live | 30 min d'inactivité, slot unique (dernier push gagne), révocation immédiate ; propositions 15 min, purgées à chaque push ; `live_ref` = révision + dossier |
| `document_ref` | 1 h d'inactivité |
| `validation_id` / `patchval_*` | 15 min, usage unique |
| `run_token` | 15 min, usage unique (consommé seulement à l'exécution) |
| Timeouts moteur | 30 s schéma, 120 s aperçu/test, 60 s codegen, 600 s run |

Toute troncature est signalée (`truncated: true` + `omissions`).

## Codes d'erreur

Les erreurs sont des `ToolError` dont le message est un JSON :

```json
{"code": "stale_document", "message": "le pipeline a changé depuis la validation", "retryable": true, "action": "Relancez pf_validate_python_column sur la version courante.", "diagnostic": null}
```

`engine_unavailable`, `engine_incompatible`, `engine_busy` (réessayez, `retryable: true`), `document_not_found`, `invalid_pipeline`, `invalid_code`, `stale_document`, `validation_expired`, `validation_consumed`, `contract_not_supported`, `unsafe_path`, `output_exists`, `output_too_large`, `io_error`, `engine_error`, `live_forbidden` (repousser depuis Studio), `live_expired` (relire `pf_live_status`), `live_read_only` (proposer via `pf_propose_patch`), `needs_studio_confirm` (« Autoriser le prochain run », le plan reste valide), `invalid_run_token` (redemander un plan).
