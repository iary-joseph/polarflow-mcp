# Outils MCP PolarFlow

Prérequis : **PolarFlow Studio lancé** pour les outils moteur ; les outils fichier fonctionnent sans.
Tous les chemins sont **absolus** (Windows). `project_dir` est obligatoire si le pipeline contient des chemins relatifs.

| Outil | Entrées | Sorties | Exécute du code |
|---|---|---|---|
| `pf_status` | — | `{mcp_version, server_version, engine{available, url, contract_version, polars_version}}` | non |
| `pf_open_pipeline` | `pipeline_path`, `project_dir?` | `{document_ref, revision, pipeline_path, project_dir, summary, expires_in_s}` | non |
| `pf_get_pipeline` | `document_ref` | `{revision, pipeline, truncated}` | non |
| `pf_schema` | `document_ref`, `node_id?` | `{revision, schemas[], truncated, omissions[]}` | non |
| `pf_node_catalog` | — | `{types: {type: {category, data_schema}}}` | non |
| `pf_preview` | `document_ref`, `node_id`, `limit?` (1..50, défaut 20) | `{revision, columns, rows, truncated, omissions}` | **oui** |
| `pf_validate_python_column` | `document_ref`, `node_id`, `code`, `execution_mode?` (`dataframe`/`batch`/`element`) | `{validation_id, node_id, execution_mode, candidate_sha256, source_revision, observation, preview, delta, duration_ms, expires_in_s}` | **oui** |
| `pf_apply_python_column_code` | `validation_id`, `accept_contract?` (défaut `true`) | `{applied, already_applied, node_id, contract_written, revision}` | non |
| `pf_codegen` | `document_ref`, `save_to`, `format?` (`script`/`notebook`), `overwrite?`, `strict?` | `{path, bytes, sha256, format, warnings, syntax_ok, run_contract_present}` | non |

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
| Aperçu | 50 lignes, cellule 4 000 caractères, réponse 256 Kio |
| Schémas | 200 nœuds, 100 colonnes par nœud |
| `document_ref` | 1 h d'inactivité |
| `validation_id` | 15 min, usage unique |
| Timeouts moteur | 30 s schéma, 120 s aperçu/test, 60 s codegen |

Toute troncature est signalée (`truncated: true` + `omissions`).

## Codes d'erreur

Les erreurs sont des `ToolError` dont le message est un JSON :

```json
{"code": "stale_document", "message": "le pipeline a changé depuis la validation", "retryable": true, "action": "Relancez pf_validate_python_column sur la version courante.", "diagnostic": null}
```

`engine_unavailable`, `engine_incompatible`, `document_not_found`, `invalid_pipeline`, `invalid_code`, `stale_document`, `validation_expired`, `validation_consumed`, `contract_not_supported`, `unsafe_path`, `output_exists`, `output_too_large`, `io_error`, `engine_error`.
