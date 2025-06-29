document.addEventListener('DOMContentLoaded', function () {
  var storageKey = 'theme';
  var classNameDark = 'dark-mode';
  var toggleButton = document.getElementById('theme-toggle');
  if (!toggleButton) return;
  var navbar = document.querySelector('nav.navbar');

  function setClass(dark) {
    if (dark) {
      document.body.classList.add(classNameDark);
      if (navbar) {
        navbar.classList.remove('is-light');
        navbar.classList.add('is-dark');
      }
    } else {
      document.body.classList.remove(classNameDark);
      if (navbar) {
        navbar.classList.remove('is-dark');
        navbar.classList.add('is-light');
      }
    }
  }

  var stored = localStorage.getItem(storageKey);
  var prefers = window.matchMedia('(prefers-color-scheme: dark)').matches;
  var darkMode = stored ? stored === 'dark' : prefers;
  setClass(darkMode);

  toggleButton.addEventListener('click', function () {
    darkMode = !darkMode;
    localStorage.setItem(storageKey, darkMode ? 'dark' : 'light');
    setClass(darkMode);
  });
});
