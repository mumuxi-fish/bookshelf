const SHELF = document.getElementById('bookshelf');
const BASE = window.location.pathname.replace(/\/[^/]*$/, '/');

async function loadBooks() {
  try {
    const res = await fetch('books.json?_=' + Date.now());
    if (!res.ok) throw new Error('Failed to load books.json');
    const data = await res.json();
    
    // Sort by newest first (if has date), then alphabetical
    const books = (data.books || []).sort((a, b) => {
      if (a.added && b.added) return new Date(b.added) - new Date(a.added);
      return (a.title || a.file).localeCompare(b.title || b.file);
    });

    if (books.length === 0) {
      SHELF.innerHTML = `<div class="empty-state">
        <div class="icon">📚</div>
        <p>书架还是空的</p>
        <p style="font-size:0.85rem;margin-top:8px">运行 <code>./update-books.sh</code> 来添加书籍</p>
      </div>`;
      return;
    }

    SHELF.innerHTML = books.map((book, i) => {
      const ext = (book.file || '').split('.').pop().toLowerCase();
      const icon = ext === 'pdf' ? '📄' : '📖';
      const title = book.title || book.file.replace(/\.\w+$/, '');
      const author = book.author || '';
      const size = book.size || '';
      const added = book.added || '';

      return `<div class="book-card" onclick="openReader('${book.file}')">
        <div class="book-cover">
          <span class="icon">${icon}</span>
        </div>
        <div class="book-info">
          <div class="book-title">${title}</div>
          ${author ? `<div class="book-author">${author}</div>` : ''}
          <div class="book-meta">
            <span>${size}${added ? ' · ' + added : ''}</span>
            <button class="read-btn" onclick="event.stopPropagation(); openReader('${book.file}')">阅读</button>
          </div>
        </div>
      </div>`;
    }).join('');
  } catch (err) {
    SHELF.innerHTML = `<div class="empty-state">
      <div class="icon">⚠️</div>
      <p>加载失败：${err.message}</p>
      <p style="font-size:0.85rem;margin-top:8px">请确认 books.json 已经生成</p>
    </div>`;
  }
}

function openReader(file) {
  const encoded = encodeURIComponent(file);
  window.open(`${BASE}viewer.html?file=${encoded}`, '_blank');
}

loadBooks();
