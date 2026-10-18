#!/usr/bin/env bash
# 安装 long-loop。目录由调用者指定，脚本不默认写入任何代理的 skills 目录。
# 目标目录里缺少的必需技能会装进同一目录。页面才用到的技能不在这里装。
#
#   bash install.sh
#   bash install.sh --target /你的/skills目录
#   bash install.sh --target /你的/skills目录 --link
#   bash install.sh --target /你的/skills目录 --skip-deps
#   bash install.sh --target /你的/skills目录 --uninstall

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="long-loop"
TARGET=""
LINK=0
SKIP_DEPS=0
UNINSTALL=0

# 每次闭环都会点名的技能。仓库路径是 git 仓库里的相对路径。
MATT_REPO="https://github.com/mattpocock/skills.git"
PONYTAIL_REPO="https://github.com/DietrichGebert/ponytail.git"
REQUIRED=(
  "grill-with-docs|matt|skills/engineering/grill-with-docs"
  "grilling|matt|skills/productivity/grilling"
  "domain-modeling|matt|skills/engineering/domain-modeling"
  "to-spec|matt|skills/engineering/to-spec"
  "to-tickets|matt|skills/engineering/to-tickets"
  "implement|matt|skills/engineering/implement"
  "implement-spec|matt|skills/engineering/implement-spec"
  "tdd|matt|skills/engineering/tdd"
  "code-review|matt|skills/engineering/code-review"
  "pr|matt|skills/engineering/pr"
  "ponytail|ponytail|skills/ponytail"
)

SEARCH_ROOTS=(
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
  "$HOME/.cursor/skills"
  "$HOME/.qoder/skills"
  "$HOME/.pi/agent/skills"
  "$HOME/.lingma/skills"
  "$HOME/.trae/skills"
)

usage() {
  cat <<'EOF'
用法：bash install.sh [--target 目录] [--link] [--skip-deps] [--uninstall]

  --target     技能目录。非交互运行时必须给出。不设默认目录。
  --link       用符号链接安装。省略时复制文件。
  --skip-deps  只安装 long-loop，不补必需技能。
  --uninstall  从该目录移除 long-loop。不移除已装上的必需技能。
EOF
}

info() { printf '✓ %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
CLONED=""
die() {
  [[ -n "$CLONED" && -d "$CLONED" ]] && rm -rf "$CLONED"
  printf '✗ %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || die "--target 需要一个目录"
      TARGET="$2"
      shift 2
      ;;
    --link) LINK=1; shift ;;
    --skip-deps) SKIP_DEPS=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1" ;;
  esac
done

resolve() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

choose_target() {
  [[ -n "$TARGET" ]] && return
  [[ -t 0 ]] || die "非交互运行需要 --target 目录"
  cat <<EOF
把 long-loop 安装到哪个目录？脚本没有默认目录。

  1) $HOME/.claude/skills
  2) $HOME/.agents/skills
  3) $HOME/.cursor/skills
  4) $HOME/.qoder/skills
  5) $HOME/.pi/agent/skills
  6) $HOME/.lingma/skills
  7) $HOME/.trae/skills
  8) 输入其他路径
EOF
  local choice
  while true; do
    printf '> '
    IFS= read -r choice
    case "$choice" in
      1) TARGET="$HOME/.claude/skills"; break ;;
      2) TARGET="$HOME/.agents/skills"; break ;;
      3) TARGET="$HOME/.cursor/skills"; break ;;
      4) TARGET="$HOME/.qoder/skills"; break ;;
      5) TARGET="$HOME/.pi/agent/skills"; break ;;
      6) TARGET="$HOME/.lingma/skills"; break ;;
      7) TARGET="$HOME/.trae/skills"; break ;;
      8)
        printf '路径> '
        IFS= read -r TARGET
        [[ -n "$TARGET" ]] || continue
        TARGET="${TARGET/#\~/$HOME}"
        break
        ;;
      *) printf '输入 1 到 8。\n' ;;
    esac
  done
}

place() {
  local src="$1" dest="$2" mode="${3:-auto}"
  src="$(resolve "$src")"
  mkdir -p "$(dirname "$dest")"
  if [[ "$mode" == "link" || ( "$mode" == "auto" && "$LINK" -eq 1 ) ]]; then
    ln -sfn "$src" "$dest"
    info "链接 $dest → $src"
    return
  fi
  if [[ -e "$dest" ]]; then
    chmod -R u+w "$dest" || true
    rm -rf "$dest"
  fi
  mkdir -p "$dest"
  cp -RL "$src/." "$dest/"
  info "复制到 $dest"
}

find_local() {
  local name="$1" root
  for root in "${SEARCH_ROOTS[@]}"; do
    [[ -f "$root/$name/SKILL.md" ]] || continue
    [[ "$(resolve "$root")" == "$(resolve "$TARGET")" ]] && continue
    printf '%s\n' "$root/$name"
    return 0
  done
  return 1
}

clone_repo() {
  local url="$1" dest="$2"
  command -v git >/dev/null 2>&1 || die "需要 git 才能下载缺失的技能"
  git clone --depth 1 "$url" "$dest"
}

install_required() {
  local missing=() spec name source rel local_path
  local matt_dir="" ponytail_dir="" tmp=""
  for spec in "${REQUIRED[@]}"; do
    name="${spec%%|*}"
    if [[ -f "$TARGET/$name/SKILL.md" ]]; then
      info "已有 $name"
      continue
    fi
    missing+=("$spec")
  done
  [[ ${#missing[@]} -eq 0 ]] && return

  tmp="$(mktemp -d)"
  CLONED="$tmp"
  for spec in "${missing[@]}"; do
    IFS='|' read -r name source rel <<<"$spec"
    if local_path="$(find_local "$name")"; then
      place "$local_path" "$TARGET/$name"
      continue
    fi
    case "$source" in
      matt)
        if [[ -z "$matt_dir" ]]; then
          matt_dir="$tmp/matt"
          info "下载 $MATT_REPO"
          clone_repo "$MATT_REPO" "$matt_dir"
        fi
        [[ -f "$matt_dir/$rel/SKILL.md" ]] || die "仓库里没有 $rel"
        # 下载目录马上会删，不能做成链接。
        place "$matt_dir/$rel" "$TARGET/$name" copy
        ;;
      ponytail)
        if [[ -z "$ponytail_dir" ]]; then
          ponytail_dir="$tmp/ponytail"
          info "下载 $PONYTAIL_REPO"
          clone_repo "$PONYTAIL_REPO" "$ponytail_dir"
        fi
        [[ -f "$ponytail_dir/$rel/SKILL.md" ]] || die "仓库里没有 $rel"
        place "$ponytail_dir/$rel" "$TARGET/$name" copy
        ;;
      *) die "未知来源：$source" ;;
    esac
  done
  rm -rf "$tmp"
  CLONED=""
}

choose_target
mkdir -p "$TARGET"
TARGET="$(resolve "$TARGET")"

if [[ "$UNINSTALL" -eq 1 ]]; then
  if [[ -e "$TARGET/$NAME" ]]; then
    chmod -R u+w "$TARGET/$NAME" || true
    rm -rf "$TARGET/$NAME"
    info "已移除 $TARGET/$NAME"
  else
    warn "$TARGET/$NAME 不存在"
  fi
  exit 0
fi

if [[ "$(resolve "$ROOT")" == "$TARGET/$NAME" ]]; then
  info "long-loop 的源目录就是 $TARGET/$NAME，跳过自身安装"
else
  place "$ROOT" "$TARGET/$NAME"
fi

if [[ "$SKIP_DEPS" -eq 0 ]]; then
  install_required
else
  info "已跳过必需技能"
fi

printf '\n安装完成：%s\n' "$TARGET/$NAME"
printf '页面用到的技能不在这次安装里。运行到那一步、目标目录里没有时再装。\n'
