#!/bin/bash
# add-books.sh — 一键添加新书：扫描下载目录→复制→更新清单→提交推送
# 用法: ./add-books.sh
# 若只想从特定文件复制: ./add-books.sh ~/Downloads/某书.pdf
# dry-run 预览: ./add-books.sh --dry-run

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOKS_DIR="$SCRIPT_DIR/books"
OUTPUT="$SCRIPT_DIR/books.json"
DOWNLOAD_DIR="$HOME/Downloads"
DRY_RUN=false

# --- Parse args ---
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=true
  shift
fi

echo "📚 书架 — 添加新书"
echo "━━━━━━━━━━━━━━━━━━"

# --- Step 1: 收集候选文件 ---
CANDIDATES=()
if [ $# -gt 0 ]; then
  # 指定了文件
  for f in "$@"; do
    ext="${f##*.}"
    if [[ "$ext" =~ ^(pdf|epub|PDF|EPUB)$ ]]; then
      CANDIDATES+=("$f")
    else
      echo "⚠️ 跳过非书籍文件: $f"
    fi
  done
else
  # 扫描下载目录
  for ext in pdf epub PDF EPUB; do
    while IFS= read -r -d '' f; do
      CANDIDATES+=("$f")
    done < <(find "$DOWNLOAD_DIR" -maxdepth 1 -name "*.$ext" -print0 2>/dev/null)
  done
fi

if [ ${#CANDIDATES[@]} -eq 0 ]; then
  echo "❌ 没有找到新的 PDF/EPUB 文件"
  echo "  用法: $0 [--dry-run] [文件路径...]"
  exit 1
fi

# --- Step 2: 对比去重 ---
EXISTING=()
while IFS= read -r -d '' f; do
  EXISTING+=("$(basename "$f")")
done < <(find "$BOOKS_DIR" -maxdepth 1 \( -name '*.pdf' -o -name '*.epub' \) -print0 2>/dev/null)

ADDED=()
SKIPPED=()

for src in "${CANDIDATES[@]}"; do
  basename="$(basename "$src")"
  
  # 清理文件名：去掉 z-library 尾巴、大图、超值全彩等冗余
  clean="$(echo "$basename" \
    | sed -E 's/ *\([^)]*(z-library[^)]*|1lib\.sk[^)]*|z-lib[^)]*|z-lib\.sk[^)]*)\)//g' \
    | sed -E 's/ *\([^)]*\)//g' \
    | sed -E 's/ *\[[^]]*\]//g' \
    | sed -E 's/ +大图//g' \
    | sed -E 's/ 超值全彩白金版//g' \
    | sed -E 's/ +/ /g' \
    | sed -E 's/^ +//; s/ +$//')"
  
  # 如果清理后跟原文件一样但已经有同名文件，跳过
  if printf '%s\n' "${EXISTING[@]}" | grep -qFx "$clean"; then
    echo "  ⏭️  已存在: $clean"
    SKIPPED+=("$clean")
    continue
  fi
  
  # 也可能清理前不同但清理后同名（如两个不同来源的同一本书）
  dest="$BOOKS_DIR/$clean"
  
  if [ -f "$dest" ]; then
    echo "  ⏭️  目标已存在: $clean"
    SKIPPED+=("$clean")
    continue
  fi
  
  if [ "$DRY_RUN" = true ]; then
    echo "  📄 [DRY-RUN] 将添加: $clean"
    ADDED+=("$clean")
  else
    cp "$src" "$dest"
    echo "  📄 已添加: $clean ($(numfmt --to=iec-i --suffix=B $(stat -f%z "$dest" 2>/dev/null || echo 0) 2>/dev/null || echo '?'))"
    ADDED+=("$clean")
  fi
done

if [ ${#ADDED[@]} -eq 0 ]; then
  echo ""
  echo "📭 没有新书需要添加 (${#SKIPPED[@]} 本已存在)"
  exit 0
fi

# --- Step 3: 更新 books.json ---
echo ""
echo "🔄 更新 books.json..."
"$SCRIPT_DIR/update-books.sh"

# --- Step 4: 提交并推送 ---
echo ""
echo "🚀 提交并推送到 GitHub..."
cd "$SCRIPT_DIR"
git add books.json books/

# 构建提交信息
if [ ${#ADDED[@]} -eq 1 ]; then
  msg="📚 添加：${ADDED[0]}"
else
  msg="📚 新增 ${#ADDED[@]} 本书"
fi
git commit -m "$msg"
git push

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 完成！${#ADDED[@]} 本新书已上线"
echo "   https://mumuxi-fish.github.io/bookshelf/"
echo ""
echo "📊 统计: +${#ADDED[@]} 本 · 书架共 $(grep -c '"file":' "$OUTPUT") 本"
