#!/bin/bash
# update-books.sh — 扫描 books/ 目录，自动生成 books.json
# 用法: ./update-books.sh
# 有新书时: 把 PDF 放到 books/ 下，运行此脚本，然后 git add && git push

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOKS_DIR="$SCRIPT_DIR/books"
OUTPUT="$SCRIPT_DIR/books.json"

if [ ! -d "$BOOKS_DIR" ]; then
  echo "❌ books/ 目录不存在"
  exit 1
fi

python3 << PYEOF
import json, os, glob, time

books_dir = "$BOOKS_DIR"
output = "$OUTPUT"

files = []
for ext in ('*.pdf', '*.epub', '*.PDF', '*.EPUB'):
    files.extend(glob.glob(os.path.join(books_dir, ext)))

# Remove duplicates
files = sorted(set(files), key=os.path.getmtime)

books = []
for f in files:
    basename = os.path.basename(f)
    title = os.path.splitext(basename)[0]
    
    size_bytes = os.path.getsize(f)
    if size_bytes > 1073741824:
        size_str = f"{size_bytes/1073741824:.1f} GB"
    elif size_bytes > 1048576:
        size_str = f"{size_bytes/1048576:.1f} MB"
    else:
        size_str = f"{size_bytes/1024:.0f} KB"
    
    mtime = os.path.getmtime(f)
    added = time.strftime('%Y-%m-%d', time.localtime(mtime))
    
    books.append({
        'file': basename,
        'title': title,
        'size': size_str,
        'added': added
    })

with open(output, 'w', encoding='utf-8') as f:
    json.dump({'books': books}, f, ensure_ascii=False, indent=2)

print(f"✅ 已生成 books.json")
print(f"   共 {len(books)} 本书")
PYEOF

echo ""
echo "现在提交推送即可更新书架："
echo "  git add books.json books/"
echo '  git commit -m "更新书籍清单"'
echo "  git push"
