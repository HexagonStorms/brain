# local-llm

Local-model coding with **aider** (terminal pair-programmer) backed by **Ollama**
(local model server). Currently set up on **Polaris** only — the defaults here are
tuned for its RTX 5080 (16 GB VRAM) + 64 GB RAM.

Ollama is just the engine; aider is the driver. Ollama runs the model and has no
file access, no permissions, and no memory. aider provides the repo awareness
(a tree-sitter *repo map*, **not** a vector/RAG database), git auto-commits, and
the per-repo `CONVENTIONS.md` memory file. There is no `ollama.md`.

## Files here

| File | Purpose |
|------|---------|
| `aider.conf.yml` | Global aider defaults — model, `yes-always`, dark mode. Symlinked to `~/.aider.conf.yml` by `setup.sh`. |
| `aider.model.settings.yml` | Per-model `num_ctx` overrides. Symlinked to `~/.aider.model.settings.yml`. |

`setup.sh` links both into `$HOME`. They're inert on a machine without aider+ollama,
so the symlinks are harmless everywhere; only Polaris currently uses them.

## Fresh-machine setup

1. **Ollama** — install it and pull models:
   ```sh
   ollama pull qwen2.5-coder:14b      # daily driver
   ollama pull qwen3.6:35b            # heavy/slow option
   ```
2. **aider** — install pinned to Python 3.12. (linuxbrew's `python3` is 3.14, which
   has no scipy wheel, so the default `pipx install aider-chat` fails building scipy
   from source.)
   ```sh
   pipx install --python /usr/bin/python3.12 aider-chat
   ```
3. **brain wiring** — `zsh ~/Code/brain/setup.sh` symlinks the config files home.
4. **Keep aider's scratch out of git** (one-time, global):
   ```sh
   git config --global core.excludesfile ~/.gitignore_global
   printf '\n.aider*\n' >> ~/.gitignore_global
   ```
5. **(optional) shell env** — add to `~/.zshrc` to silence aider's endpoint warning:
   ```sh
   export OLLAMA_API_BASE=http://127.0.0.1:11434
   ```

## The #1 gotcha: context window

Ollama defaults to a **2048-token** context and *silently truncates* past it —
which quietly cripples coding (repo map + files blow past 2048 instantly).
`aider.model.settings.yml` raises `num_ctx` to 16384 per model. If you `ollama pull`
a new coding model, add it there too.

## Models (Polaris, 16 GB VRAM)

| Model | When |
|-------|------|
| `qwen2.5-coder:14b` | Daily driver. Fits VRAM, fast. (the configured default) |
| `qwen3.6:35b` | Heavier/smarter, but 23 GB spills to RAM → slow. `aider --model ollama_chat/qwen3.6:35b` |
| `deepseek-coder-v2` | Fast MoE alternate. |
| `deepseek-r1:*` | Reasoning model — **skip for editing** (weak at diff formats). |

## How to run

```sh
cd ~/Code/<repo>
aider                       # uses the global config + 14b
```

Inside the session:

- **`/ask <question>`** — brainstorm / discuss / plan, *no edits made*. Repo-map aware.
- **`/architect <task>`** — reasoning pass writes a plan, editor pass applies the code.
- **`/code <task>`** (default) — just make the change.
- You don't have to `/add` files first; aider proposes them from the repo map.
  `/add <file>` is the manual override when it picks wrong (more common with local models).
- **`/diff`** review, **`/test <cmd>`** run tests, **`/undo`** revert its last commit.

Plan-then-build flow:
```
/ask What's the cleanest way to add feature X here?
/architect Implement that plan.
/test npm test
```

Quality is model-bound: a local 14b is solid for scoped implementation, modest at
open-ended architecture. For hard design, plan with a strong model (Claude Code),
then hand the plan to the local coder to grind out.

## Permissions

`yes-always: true` is set, so aider applies edits, adds files, and **runs suggested
shell commands without prompting**. Edit mistakes are recoverable via `/undo` (git);
shell side effects (`rm`, migrations, deploys) are **not** — stay aware of what it
runs. Override for a single session with `aider --no-yes-always`.

## Per-repo conventions (memory)

aider auto-loads a `CONVENTIONS.md` at the repo root — its equivalent of `CLAUDE.md`.
Copy one in per project and tune the stack/test lines.

**Work repos (`~/Code/automatiq/*`):** the `CONVENTIONS.md` files live in the repo
working tree but are kept **untracked & local-only** via `.git/info/exclude`
(`/CONVENTIONS.md`) — they are never committed, and work conventions never enter this
personal HexagonStorms repo. Currently seeded in: `brokergenius`, `v4.0`, `automatiq-iq`.

## Identity (when running aider in work repos)

automatiq repos must use the **joshplaza** GitHub account, never HexagonStorms.
This is enforced by SSH, not by the convention text: automatiq remotes use the
`github-automatiq` host alias (key `id_ed25519_automatiq`) + `josh.plaza@automatiq.com`
via a `~/Code/automatiq` git conditional include. Personal repos use `github.com`
(`id_ed25519`) as HexagonStorms. Don't change a work repo's remote or author.

## Not here (yet)

- **Ops agent** — "do stuff on my PC / SSH elowynn / manage Hetzner sites" is a
  *different* tool (Goose / OpenCode / Claude Code over MCP), not aider. It gets a
  stricter permission posture — never blanket `yes-always` against real servers.
- **Ollama Modelfiles** — if we bake `num_ctx`/system prompts into custom models,
  the Modelfiles belong here too.
