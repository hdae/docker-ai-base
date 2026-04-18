# Changelog

本プロジェクトの特筆すべき変更点を記録します。 フォーマットは
[Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に、 バージョニングは
[Semantic Versioning](https://semver.org/lang/ja/) に準拠します
(正式なリリースタグはまだ切っていません)。

## [Unreleased] - 2026-04-18

破壊的変更を複数含むレビューベースの整備リリース。 移行手順は
[下記](#移行ガイド-unreleased) を参照。

### Breaking Changes

- **環境変数リネーム**: entrypoint が export する `APP_DIR` を `WORKSPACE_DIR`
  に改名。`start.sh` 内で `$APP_DIR` を参照していた場合は `$WORKSPACE_DIR`
  に置換が必要。([276fb12])
- **uv-cache マウント先変更**: `UV_CACHE_DIR` を `/workspace/.uv-cache` から
  `/opt/uv-cache` に移動。`/workspace` 配下に置くと `app-data` ボリュームや
  バインドマウントで容易にシャドウされる問題を回避。既存の `shared_uv-cache`
  ボリュームはそのまま再利用可能(中身のパスが変わる だけ)。([8bab615])
- **`working_dir` 変更**: テンプレート compose の `working_dir` を
  `/workspace/app` から `/workspace` に統一。Dockerfile の `WORKDIR` と
  整合。`/workspace/app` を前提にしたワークフローはパス修正が必要。 ([8bab615])
- **イメージタグ方針変更**: `task build` は `hdae/ai-base:bookworm` と
  `hdae/ai-base:latest` を同時に付与。`task build.debian` は
  `hdae/ai-base:<debian_version>` を付与する形に変更し、同一タグ上書きを
  防止。タグなしの `hdae/ai-base` を参照している場合は `:latest` に
  追随するため暗黙的には互換だが、タグ明示を推奨。([bef4193])
- **`push` タスク削除**: レジストリ未設定のまま置かれていたルート `task push`
  を削除。([bef4193])
- **デフォルト `CMD` 削除**: base image から `CMD ["bash"]` を削除。
  downstream の `start.sh` がしばしば `$# > 0 → exec "$@"` の
  pass-through 分岐を持っており、親の `bash` が素通りでサーバー起動を
  乗っ取る事故が起きていたため。以降は consumer 側で `command:` または
  Dockerfile の `CMD` を明示するか、`/start.sh` をマウントする必要が
  ある。`docker run -it hdae/ai-base` だけで shell に入りたい場合は
  末尾に `bash` を付ける。([3e424fa])

### Added

- `scripts/init.sh`: テンプレート展開ヘルパー。宛先ディレクトリを引数に
  取り、dotfile も含めコピー、`README.md` を `TEMPLATE_README.md` に
  リネーム、`start.sh` に実行権を付与する。([f09a6c4])
- `templates/.env.example`: `PUID` / `PGID` / `PYTHON_VERSION` /
  `COMPOSE_PROJECT_NAME` の雛形。([8bab615])
- `base/.dockerignore`: ビルドコンテキストを Dockerfile と entrypoint.sh
  のみに限定。([913c005])
- `docker-compose.yml` に `stdin_open: true` を追加し、対話デバッグを
  快適に。([8bab615])

### Changed

- **entrypoint の chown 最適化**: `/workspace` (および `UV_CACHE_DIR`)
  全体を毎回 `chown -R`
  する代わりに、`find ... -not -user app -o
  -not -group ...`
  で所有者不一致のエントリだけ `chown` するよう変更。
  大量ファイルを含むキャッシュを抱える場合、2 回目以降の起動が
  著しく速くなる。([276fb12], [6f92126])
- **Dockerfile の GID/UID 衝突ガード**: UID/GID 1000 が既に存在する
  ベースイメージでもビルドが通るよう、`getent` による存在チェック +
  `groupmod -n` / `usermod -l` へのフォールバックを追加。([276fb12])
- **`reset` / `purge` の責務分離**: これまで実質同じだった両タスクを
  整理。`reset` は `app-data` のみ削除、`purge` は `docker compose
  down -v` +
  `shared_uv-cache` も削除するように。プロンプト文言も 明確化。([7ffd288])
- ドキュメント (`README.md`, `templates/README.md`) を新構成に追従。
  本番運用時の `restart: unless-stopped` 推奨、新マウントパス、
  新タグ方針を明記。([f3e02fb])

### Fixed

- **uv-cache ボリュームの初期所有者**: `/opt/uv-cache` を Dockerfile で
  `app:app` 所有で pre-create。新規 named volume の初回マウント時に Docker
  がこの内部パスの所有者で volume を seed するため、root:root の
  キャッシュに書き込めない不具合を予防。既存ボリューム救済として entrypoint でも
  `UV_CACHE_DIR` を chown 対象に追加。([6f92126])
- **`clone_or_update` の tag fetch 漏れ**: 既存チェックアウトで
  `git fetch origin --quiet` しか叩いておらず、新規タグ (`v1.0.0` → `v1.1.0`
  など)への切替が失敗していた。`--tags --prune` を付与して 修正。([a815464])
- **`build.debian` のタグ上書き**: Debian バージョン違いを並行ビルド しても同じ
  `hdae/ai-base` タグを上書きしていた問題を解消。 ([bef4193])
- **entrypoint の chown が dangling symlink で失敗する**: uv の sdists
  キャッシュは一時ビルドディレクトリ(削除済み)を指す broken symlink を
  含むことがあり、所有者補正時の `chown` が dereference を試みて
  `cannot dereference` で落ちていた。`chown -h` でリンク自体を
  retag するように変更。([35e22ad])

## 移行ガイド (Unreleased)

前バージョン(`ea90c55` 以前)から移行するときのチェックリスト。

### 1. `start.sh` の `APP_DIR` 参照を置換

```bash
# Before
uv pip install -r "$APP_DIR/app/requirements.txt"

# After
uv pip install -r "$WORKSPACE_DIR/app/requirements.txt"
```

`templates/start.sh` は既に更新済み。独自の `start.sh` を運用して
いる場合のみ対応が必要。

### 2. `docker-compose.yml` の uv-cache マウントを更新

```yaml
# Before
environment:
  - UV_CACHE_DIR=/workspace/.uv-cache
volumes:
  - uv-cache:/workspace/.uv-cache

# After
environment:
  - UV_CACHE_DIR=/opt/uv-cache
volumes:
  - uv-cache:/opt/uv-cache
```

`shared_uv-cache` ボリューム自体は流用可能。

### 3. `working_dir` を確認

独自に `working_dir: /workspace/app` を指定していた場合、`/workspace`
に戻すか、アプリ側のパスを明示する。テンプレートは `/workspace`。

### 4. 新規ビルドでタグを再確認

`task build` 実行後、自身の compose で参照しているタグが `hdae/ai-base` (=
`:latest` 相当)か `hdae/ai-base:bookworm` かを確認。 タグを明示しておくと将来の
Debian 切替時に安全。

### 5. 既存の `shared_uv-cache` が root 所有の場合

旧構成で既に root:root のキャッシュが作られていた場合、新 entrypoint が
起動時に自動で `chown` し直すため追加作業は不要。どうしても気になる
ときは以下で作り直せる。

```bash
task purge   # app-data と shared_uv-cache を削除
task up      # 新構成で再作成
```

### 6. 独自 `Dockerfile` の `ENV` を更新

downstream で `FROM hdae/ai-base` な Dockerfile を持っている場合、
`APP_DIR` 指定と `UV_CACHE_DIR` の旧パスを更新する(base の ENV は
downstream 側の指定で shadow されるため)。

```dockerfile
# Before
ENV APP_DIR=/workspace \
    PROJECT_ROOT=/workspace/app \
    UV_CACHE_DIR=/workspace/.uv-cache

# After (APP_DIR は不要、UV_CACHE_DIR は /opt/uv-cache)
ENV PROJECT_ROOT=/workspace/app \
    UV_CACHE_DIR=/opt/uv-cache
```

### 7. `CMD ["bash"]` 削除への対応

base image のデフォルト `CMD ["bash"]` が撤去されたことに伴う確認事項。

- compose で `command:` も Dockerfile で `CMD` も指定せず、`/start.sh`
  もマウントしていない場合、コンテナは entrypoint 完了後そのまま正常終了
  (exit 0)する。サーバーを起動したい場合は `command:` / `CMD` / `start.sh`
  いずれかで明示。
- 親 CMD `bash` が `start.sh` の `$# > 0 → exec "$@"` 分岐で
  hijack されて「サーバーが起動せず bash が立ち上がる」事故を回避する
  ため、暫定対処として `command: []` を compose に入れていた場合は、
  もう不要なので削除して構わない。
- `docker run -it hdae/ai-base` だけで shell に入る運用をしていた場合は
  `docker run -it hdae/ai-base bash` のように末尾に `bash` を付ける。

[276fb12]: https://github.com/hdae/docker-ai-base/commit/276fb12
[bef4193]: https://github.com/hdae/docker-ai-base/commit/bef4193
[8bab615]: https://github.com/hdae/docker-ai-base/commit/8bab615
[7ffd288]: https://github.com/hdae/docker-ai-base/commit/7ffd288
[a815464]: https://github.com/hdae/docker-ai-base/commit/a815464
[f09a6c4]: https://github.com/hdae/docker-ai-base/commit/f09a6c4
[913c005]: https://github.com/hdae/docker-ai-base/commit/913c005
[f3e02fb]: https://github.com/hdae/docker-ai-base/commit/f3e02fb
[6f92126]: https://github.com/hdae/docker-ai-base/commit/6f92126
[35e22ad]: https://github.com/hdae/docker-ai-base/commit/35e22ad
[3e424fa]: https://github.com/hdae/docker-ai-base/commit/3e424fa
