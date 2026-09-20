# AGENTS.md — dépôt PolarFlow MCP

Ce dépôt distribue un **skill** et un **serveur MCP** pour piloter PolarFlow Studio depuis un assistant IA (Claude Code, Codex).

## Si un utilisateur te demande d'installer le MCP PolarFlow

1. Lis `INSTALL.md` et applique la section du client utilisé.
2. Préfère le chemin le plus court :
   - Claude Code : `/plugin marketplace add iary-joseph/polarflow-mcp` puis `/plugin install polarflow@polarflow-mcp`.
   - Codex : `codex mcp add polarflow -- "<moteur>" --mcp`.
   - Script idempotent : `powershell -ExecutionPolicy Bypass -File .\plugins\polarflow\scripts\setup-mcp.ps1`.
3. Vérifie avec `pf_status` après redémarrage du client.
4. N'invente pas de configuration : si PolarFlow Studio n'est pas installé, dis-le et arrête-toi.

## Si tu utilises les outils `pf_*`

Applique le skill `plugins/polarflow/skills/polarflow/SKILL.md` :

- `pf_open_pipeline` avec des chemins **absolus** (+ `project_dir` si chemins relatifs).
- `pf_schema` / `pf_preview` pour observer avant de proposer.
- Toute modification de code passe par `pf_validate_python_column` puis `pf_apply_python_column_code` — jamais d'édition manuelle du fichier pipeline.
- Les outils qui exécutent (`pf_preview`, `pf_validate_python_column`) exigent une approbation utilisateur ; aucun retry automatique.
- `stale_document` = fichier modifié : refaire un test.
- Pas de `pf_run` : l'exécution complète reste dans l'interface Studio.

## Ce que ce dépôt n'est pas

- Pas le dépôt de PolarFlow Studio (moteur/application) : il ne contient que le plugin, le skill, le lanceur et la documentation d'installation.
- Aucun secret, aucune clé API, aucun appel LLM.
