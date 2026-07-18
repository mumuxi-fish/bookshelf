# 📚 书架 (Bookshelf)

个人数字书架，通过 GitHub Pages 在线阅读 PDF 书籍。

## 添加新书

1. 把 PDF 放入 `books/` 目录
2. 运行 `./update-books.sh` 更新清单
3. 提交并推送

```bash
cp ~/Downloads/新书.pdf books/
./update-books.sh
git add .
git commit -m "添加新书：新书"
git push
```

GitHub Actions 会自动部署 Pages。
