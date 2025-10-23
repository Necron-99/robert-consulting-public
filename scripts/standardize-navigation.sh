#!/bin/bash

# Standardize Navigation Across All Pages
echo "=== STANDARDIZING NAVIGATION ACROSS ALL PAGES ==="

# List of pages to update
PAGES=(
    "website/index.html"
    "website/learning.html"
    "website/blog.html"
    "website/dashboard.html"
    "website/monitoring.html"
    "website/status.html"
    "website/stats.html"
    "website/best-practices.html"
)

# Create backup directory
mkdir -p website/backup-$(date +%Y%m%d-%H%M%S)

# Function to update navigation in a file
update_navigation() {
    local file="$1"
    local backup_dir="website/backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$file" ]; then
        echo "Updating navigation in $file"
        
        # Backup original
        cp "$file" "$backup_dir/$(basename "$file")"
        
        # Extract content between navigation tags
        sed -n '/<nav class="navbar">/,/<\/nav>/p' "$file" > /tmp/old_nav.html
        
        # Replace navigation section
        sed -i '/<nav class="navbar">/,/<\/nav>/c\
<!-- Navigation Component -->\
<nav class="navbar">\
    <div class="nav-container">\
        <div class="nav-logo">\
            <h2>Robert Consulting</h2>\
            <span class="nav-tagline">DevSecOps & Cloud Engineering</span>\
        </div>\
        <ul class="nav-menu" id="nav-menu">\
            <li class="nav-item">\
                <a href="index.html" class="nav-link">Home</a>\
            </li>\
            <li class="nav-item">\
                <a href="index.html#services" class="nav-link">Services</a>\
            </li>\
            <li class="nav-item">\
                <a href="learning.html" class="nav-link">Learning</a>\
            </li>\
            <li class="nav-item">\
                <a href="blog.html" class="nav-link">Blog</a>\
            </li>\
            <li class="nav-item dropdown">\
                <a href="#" class="nav-link dropdown-toggle" id="more-menu-toggle">More</a>\
                <ul class="dropdown-menu" id="more-menu">\
                    <li><a href="index.html#about" class="dropdown-link">About</a></li>\
                    <li><a href="dashboard.html" class="dropdown-link">Dashboard</a></li>\
                    <li><a href="best-practices.html" class="dropdown-link">Best Practices</a></li>\
                    <li><a href="index.html#experience" class="dropdown-link">Experience</a></li>\
                    <li><a href="index.html#contact" class="dropdown-link">Contact</a></li>\
                </ul>\
            </li>\
        </ul>\
        <div class="nav-actions">\
            <button type="button" id="theme-toggle-btn" class="btn btn-ghost btn-icon" aria-label="Toggle theme" title="Toggle theme">\
                <span class="icon-moon" id="theme-icon">🌙</span>\
            </button>\
        </div>\
        <button type="button" class="hamburger" id="hamburger" aria-expanded="false" aria-controls="nav-menu" aria-label="Menu">\
            <span class="bar"></span>\
            <span class="bar"></span>\
            <span class="bar"></span>\
        </button>\
    </div>\
</nav>' "$file"
    fi
}

# Update all pages
for page in "${PAGES[@]}"; do
    update_navigation "$page"
done

echo "=== NAVIGATION STANDARDIZATION COMPLETE ==="
