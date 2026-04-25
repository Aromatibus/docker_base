FROM ubuntu:24.04

# 非対面モード
ENV DEBIAN_FRONTEND=noninteractive

# インストールするパッケージリスト（重複注意、アルファベット順を守ろう！！）
ARG INSTALL_PACKAGES=" \
  build-essential \
  ca-certificates \
  curl \
  fzf \
  git \
  ibus \
  ibus-mozc \
  lf \
  locales \
  sudo \
  tree \
  unzip \
  vim \
  zoxide \
  zsh \
  "

# root で必須パッケージとリポジトリの設定
RUN apt-get update && apt-get install -y --no-install-recommends \
  software-properties-common \
  && add-apt-repository -y universe \
  && apt-get update \
  && apt-get install -y --no-install-recommends $INSTALL_PACKAGES \
  && locale-gen en_US.UTF-8 \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# ロケールの設定
ENV LANG=en_US.UTF-8

# ユーザーの定義と作成（Ubuntu 24.04 の既存ユーザー 'ubuntu' 回避策）
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN if id -u 1000 >/dev/null 2>&1; then \
  existing_user=$(id -nu 1000); \
  groupmod --new-name ${USERNAME} ${existing_user}; \
  usermod --login ${USERNAME} --move-home --home /home/${USERNAME} ${existing_user}; \
  else \
  groupadd --gid ${USER_GID} ${USERNAME}; \
  useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /usr/bin/zsh; \
  fi \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
  && chmod 0440 /etc/sudoers.d/${USERNAME}

# ユーザー権限に切り替え
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# 環境変数の設定
ENV UV_CACHE_DIR=/home/${USERNAME}/.rye/uv_cache
ENV GTK_IM_MODULE=ibus
ENV QT_IM_MODULE=ibus
ENV XMODIFIERS=@im=ibus

# zsh プラグインのインストール（軽量化のため --depth 1 を指定）
RUN mkdir -p ~/.zsh/plugins && \
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions && \
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting && \
  git clone --depth 1 https://github.com/zsh-users/zsh-completions ~/.zsh/plugins/zsh-completions

# Rye のインストール
ENV RYE_HOME=/home/${USERNAME}/.rye
ENV PATH=${RYE_HOME}/shims:${PATH}
ENV UV_LINK_MODE=copy
RUN curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash

# 設定ファイルの反映
COPY --chown=${USERNAME}:${USERNAME} .devcontainer/.zshrc /tmp/host_zshrc
RUN cat /tmp/host_zshrc >> ~/.zshrc && rm /tmp/host_zshrc

# ワーキングディレクトリの設定
WORKDIR /workspaces
