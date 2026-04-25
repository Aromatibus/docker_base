project_name := file_name(justfile_directory())

# ==========================================
# Ryeプロジェクトの初期化
# ==========================================
init:
  @echo "Initializing project: {{project_name}}..."
  # pyproject.tomlの存在を確認し、なければRyeプロジェクトを初期化する
  @if [ ! -f "pyproject.toml" ]; then \
    echo "Initializing Rye project: {{project_name}}..."; \
    docker run --rm -v "$(pwd):/app" -w /app debian:bookworm-slim /bin/bash -c " \
      apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates \
      && curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION='--yes' bash \
      && /root/.rye/shims/rye init --virtual --no-readme --name {{project_name}} ."; \
  else \
    echo "pyproject.toml already exists. Skipping init."; \
  fi
  # ホスト側で作られた .venv がある場合、コンテナとの競合を防ぐため削除する
  @if [ -d ".venv" ]; then \
    echo "Removing host-side .venv to prevent path relocation issues..."; \
    rm -rf .venv; \
  fi
  # .envファイルの存在を確認し、なければ作成する
  @if [ -f ".env" ]; then \
    echo ".env already exists. Skipping creation."; \
  else \
    touch .env; \
    echo ".env created."; \
  fi

# ==========================================
# コンテナのビルドと起動
# ==========================================
setup:
  docker build -t {{project_name}}-image -f .devcontainer/Dockerfile .
  docker run -d --name {{project_name}} --hostname {{project_name}} \
    -v "{{project_name}}_rye_cache:/home/vscode/.rye" \
    -v "$(pwd):/workspaces" \
    --env-file .env \
    -w /workspaces \
    {{project_name}}-image \
    tail -f /dev/null

# ==========================================
# 環境の再構築（Dockerfile変更時用）
# ==========================================
rebuild: clean setup

# ==========================================
# ホストからコンテナ内に入る
# ==========================================
shell:
  @docker ps | grep -q {{project_name}} || just setup
  docker exec -it {{project_name}} /bin/zsh

# ==========================================
# プロジェクトに関連するリソースを完全に削除
# ==========================================
clean:
  @echo "Cleaning up project: {{project_name}}..."
  @# 特定の名前のコンテナを強制削除
  @docker rm -f {{project_name}} 2>/dev/null || true
  @# このイメージを使っているすべてのコンテナを特定して削除
  @if docker image inspect {{project_name}}-image > /dev/null 2>&1; then \
    echo "Removing containers using image: {{project_name}}-image"; \
    docker ps -a -q --filter "ancestor={{project_name}}-image" | xargs -r docker rm -f; \
    echo "Removing Docker image: {{project_name}}-image"; \
    docker rmi {{project_name}}-image; \
  fi
  @echo "Reset Owner permissions..."
  sudo chown -R $(id -u):$(id -g) .
  @echo "Cleaning up pycache..."
  find . -type d -name '__pycache__' -exec rm -rf {} +
  @echo "removing .venv..."
  rm -rf .venv
  @echo "removing dist..."
  rm -rf dist

# ==========================================
# ボリュームも含めて完全に抹消
# ==========================================
erase: clean
  @echo "Removing Docker volumes and pruning system..."
  @docker volume rm {{project_name}}_rye_cache 2>/dev/null || true

# ==========================================
# Dockerのシステム全体をクリーンアップ
# ==========================================
nuke: erase
  @docker system prune -a --volumes -f
