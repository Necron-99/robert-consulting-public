// Theme Toggle JavaScript

class ThemeToggle {
  constructor() {
    this.themeToggleBtn = document.getElementById('theme-toggle-btn');
    this.themeIcon = document.getElementById('theme-icon');
    this.body = document.body;
    this.currentTheme = this.getStoredTheme() || 'dark';

    this.init();
  }

  init() {
    // Apply stored theme on page load
    this.applyTheme(this.currentTheme);

    // Add event listener for theme toggle
    if (this.themeToggleBtn) {
      this.themeToggleBtn.addEventListener('click', () => this.toggleTheme());
    }

    // Listen for system theme changes
    if (window.matchMedia) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!this.getStoredTheme()) {
          this.applyTheme(e.matches ? 'dark' : 'light');
        }
      });
    }
  }

  getStoredTheme() {
    return localStorage.getItem('theme');
  }

  setStoredTheme(theme) {
    localStorage.setItem('theme', theme);
  }

  applyTheme(theme) {
    this.currentTheme = theme;

    // Remove existing theme classes
    this.body.classList.remove('dark-theme', 'light-theme');

    // Add new theme class
    this.body.classList.add(`${theme}-theme`);

    // Update icon
    this.updateIcon(theme);

    // Store preference
    this.setStoredTheme(theme);

    // Dispatch custom event
    window.dispatchEvent(new CustomEvent('themeChanged', {
      detail: {theme: theme}
    }));
  }

  toggleTheme() {
    const newTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
    this.applyTheme(newTheme);
  }

  updateIcon(theme) {
    if (this.themeIcon) {
      this.themeIcon.textContent = theme === 'dark' ? '☀️' : '🌙';
    }
  }

  // Public method to get current theme
  getCurrentTheme() {
    return this.currentTheme;
  }

  // Public method to set theme programmatically
  setTheme(theme) {
    if (theme === 'dark' || theme === 'light') {
      this.applyTheme(theme);
    }
  }
}

// Initialize theme toggle when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
  window.themeToggle = new ThemeToggle();
});

// Export for external use
window.ThemeToggle = ThemeToggle;
