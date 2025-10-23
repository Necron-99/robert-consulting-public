
// Dropdown Menu Functionality
document.addEventListener('DOMContentLoaded', function() {
    const moreMenuToggle = document.getElementById('more-menu-toggle');
    const moreMenu = document.getElementById('more-menu');
    
    if (moreMenuToggle && moreMenu) {
        // Toggle dropdown on click
        moreMenuToggle.addEventListener('click', function(e) {
            e.preventDefault();
            moreMenu.classList.toggle('active');
        });
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!moreMenuToggle.contains(e.target) && !moreMenu.contains(e.target)) {
                moreMenu.classList.remove('active');
            }
        });
        
        // Close dropdown on escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                moreMenu.classList.remove('active');
            }
        });
    }
});
