(function () {
  var root = document.documentElement;
  var toggle = document.getElementById('darkModeToggle');
  var saved = localStorage.getItem('theme');
  if (saved === 'dark' || saved === 'light') {
    root.setAttribute('data-bs-theme', saved);
  }
  function syncIcon() {
    if (toggle) {
      toggle.textContent = root.getAttribute('data-bs-theme') === 'dark' ? '☀️' : '🌙';
    }
  }
  syncIcon();
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = root.getAttribute('data-bs-theme') === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-bs-theme', next);
      localStorage.setItem('theme', next);
      syncIcon();
    });
  }
})();
