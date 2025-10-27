// Logo Watermark Toggle
// Optional feature to show/hide the subtle logo watermark

document.addEventListener('DOMContentLoaded', function() {
    const watermark = document.querySelector('.logo-watermark');
    
    if (!watermark) return;
    
    // Check if user prefers reduced motion
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    
    // Only show watermark on larger screens and if user hasn't disabled it
    const shouldShowWatermark = () => {
        const isLargeScreen = window.innerWidth >= 1024;
        const userPreference = localStorage.getItem('showLogoWatermark');
        
        // Default to true for large screens, respect user preference
        if (userPreference === 'false') return false;
        if (userPreference === 'true') return true;
        return isLargeScreen;
    };
    
    // Toggle watermark visibility
    const toggleWatermark = () => {
        const show = shouldShowWatermark();
        watermark.style.display = show ? 'block' : 'none';
        
        if (show && !prefersReducedMotion) {
            // Add subtle animation
            watermark.style.opacity = '0';
            watermark.style.transition = 'opacity 0.5s ease-in-out';
            requestAnimationFrame(() => {
                watermark.style.opacity = '0.03';
            });
        }
    };
    
    // Initial setup
    toggleWatermark();
    
    // Handle window resize
    let resizeTimeout;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(toggleWatermark, 250);
    });
    
    // Optional: Add keyboard shortcut to toggle watermark (Ctrl+Shift+L)
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.shiftKey && e.key === 'L') {
            e.preventDefault();
            const currentPreference = localStorage.getItem('showLogoWatermark');
            const newPreference = currentPreference === 'false' ? 'true' : 'false';
            localStorage.setItem('showLogoWatermark', newPreference);
            toggleWatermark();
            
            // Show brief notification
            const notification = document.createElement('div');
            notification.textContent = `Logo watermark ${newPreference === 'true' ? 'enabled' : 'disabled'}`;
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: var(--surface-primary);
                color: var(--text-primary);
                padding: 12px 16px;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                z-index: 1000;
                font-size: 14px;
                font-weight: 500;
                border: 1px solid var(--border-primary);
            `;
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.opacity = '0';
                notification.style.transition = 'opacity 0.3s ease-out';
                setTimeout(() => notification.remove(), 300);
            }, 2000);
        }
    });
    
    // Optional: Add toggle button to theme controls
    const themeToggle = document.getElementById('theme-toggle-btn');
    if (themeToggle && themeToggle.parentNode) {
        const watermarkToggle = document.createElement('button');
        watermarkToggle.type = 'button';
        watermarkToggle.className = 'btn btn-ghost btn-icon';
        watermarkToggle.setAttribute('aria-label', 'Toggle logo watermark');
        watermarkToggle.setAttribute('title', 'Toggle logo watermark (Ctrl+Shift+L)');
        watermarkToggle.innerHTML = '🎨';
        
        watermarkToggle.addEventListener('click', () => {
            const currentPreference = localStorage.getItem('showLogoWatermark');
            const newPreference = currentPreference === 'false' ? 'true' : 'false';
            localStorage.setItem('showLogoWatermark', newPreference);
            toggleWatermark();
        });
        
        themeToggle.parentNode.insertBefore(watermarkToggle, themeToggle.nextSibling);
    }
});
