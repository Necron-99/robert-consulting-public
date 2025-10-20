/**
 * Best Practices Page Script
 * Handles interactive features and checklist functionality
 */

class BestPracticesManager {
    constructor() {
        this.checklistData = this.loadChecklistData();
        this.init();
    }

    init() {
        console.log('📚 Initializing Best Practices Manager...');
        
        // Set up interactive features
        this.setupChecklistInteractivity();
        this.setupSmoothScrolling();
        this.setupProgressTracking();
        this.setupCodeExamples();
        
        console.log('✅ Best Practices Manager initialized');
    }

    setupChecklistInteractivity() {
        const checkboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]');
        
        checkboxes.forEach(checkbox => {
            checkbox.addEventListener('change', () => {
                this.updateChecklistProgress();
                this.saveChecklistData();
                this.showProgressNotification();
            });
        });
    }

    setupSmoothScrolling() {
        // Smooth scrolling for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', (e) => {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            });
        });
    }

    setupProgressTracking() {
        // Update progress on page load
        this.updateChecklistProgress();
        
        // Update progress periodically
        setInterval(() => {
            this.updateChecklistProgress();
        }, 5000);
    }

    setupCodeExamples() {
        // Add copy functionality to code examples
        const codeExamples = document.querySelectorAll('.code-example');
        
        codeExamples.forEach(example => {
            const copyButton = document.createElement('button');
            copyButton.className = 'copy-button';
            copyButton.innerHTML = '📋 Copy';
            copyButton.style.cssText = `
                position: absolute;
                top: 0.5rem;
                right: 0.5rem;
                background: #38a169;
                color: white;
                border: none;
                padding: 0.25rem 0.5rem;
                border-radius: 4px;
                font-size: 0.75rem;
                cursor: pointer;
                opacity: 0;
                transition: opacity 0.2s ease;
            `;
            
            example.style.position = 'relative';
            example.appendChild(copyButton);
            
            // Show copy button on hover
            example.addEventListener('mouseenter', () => {
                copyButton.style.opacity = '1';
            });
            
            example.addEventListener('mouseleave', () => {
                copyButton.style.opacity = '0';
            });
            
            // Copy functionality
            copyButton.addEventListener('click', async() => {
                const code = example.querySelector('pre').textContent;
                try {
                    await navigator.clipboard.writeText(code);
                    copyButton.innerHTML = '✅ Copied!';
                    setTimeout(() => {
                        copyButton.innerHTML = '📋 Copy';
                    }, 2000);
                } catch (err) {
                    console.error('Failed to copy code:', err);
                }
            });
        });
    }

    updateChecklistProgress() {
        const categories = document.querySelectorAll('.checklist-category');
        
        categories.forEach(category => {
            const checkboxes = category.querySelectorAll('input[type="checkbox"]');
            const checkedBoxes = category.querySelectorAll('input[type="checkbox"]:checked');
            const progress = (checkedBoxes.length / checkboxes.length) * 100;
            
            // Create or update progress bar
            let progressBar = category.querySelector('.progress-bar');
            if (!progressBar) {
                progressBar = document.createElement('div');
                progressBar.className = 'progress-bar';
                category.appendChild(progressBar);
            }
            
            let progressFill = progressBar.querySelector('.progress-fill');
            if (!progressFill) {
                progressFill = document.createElement('div');
                progressFill.className = 'progress-fill';
                progressBar.appendChild(progressFill);
            }
            
            progressFill.style.width = `${progress}%`;
            
            // Update category title with progress
            const title = category.querySelector('h3');
            const originalTitle = title.textContent.replace(/\s*\(\d+%\)$/, '');
            title.textContent = `${originalTitle} (${Math.round(progress)}%)`;
        });
    }

    saveChecklistData() {
        const checkboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]');
        const checklistState = {};
        
        checkboxes.forEach(checkbox => {
            checklistState[checkbox.id] = checkbox.checked;
        });
        
        localStorage.setItem('best-practices-checklist', JSON.stringify(checklistState));
    }

    loadChecklistData() {
        try {
            const saved = localStorage.getItem('best-practices-checklist');
            if (saved) {
                const checklistState = JSON.parse(saved);
                
                // Restore checkbox states
                Object.entries(checklistState).forEach(([id, checked]) => {
                    const checkbox = document.getElementById(id);
                    if (checkbox) {
                        checkbox.checked = checked;
                    }
                });
                
                return checklistState;
            }
        } catch (error) {
            console.warn('Failed to load checklist data:', error);
        }
        
        return {};
    }

    showProgressNotification() {
        const totalCheckboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]').length;
        const checkedCheckboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]:checked').length;
        const progress = Math.round((checkedCheckboxes / totalCheckboxes) * 100);
        
        // Create notification
        const notification = document.createElement('div');
        notification.className = 'progress-notification';
        notification.innerHTML = `
            <div style="
                position: fixed;
                top: 20px;
                right: 20px;
                background: #38a169;
                color: white;
                padding: 1rem 1.5rem;
                border-radius: 8px;
                box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
                z-index: 1000;
                font-weight: 600;
                animation: slideInRight 0.3s ease-out;
            ">
                📊 Progress: ${progress}% Complete
            </div>
        `;
        
        document.body.appendChild(notification);
        
        // Remove notification after 3 seconds
        setTimeout(() => {
            notification.style.animation = 'slideOutRight 0.3s ease-out';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }

    // Export checklist data
    exportChecklist() {
        const totalCheckboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]').length;
        const checkedCheckboxes = document.querySelectorAll('.checklist-items input[type="checkbox"]:checked').length;
        const progress = Math.round((checkedCheckboxes / totalCheckboxes) * 100);
        
        const exportData = {
            timestamp: new Date().toISOString(),
            progress: progress,
            completed: checkedCheckboxes,
            total: totalCheckboxes,
            categories: {}
        };
        
        // Get progress by category
        document.querySelectorAll('.checklist-category').forEach(category => {
            const categoryName = category.querySelector('h3').textContent.replace(/\s*\(\d+%\)$/, '');
            const checkboxes = category.querySelectorAll('input[type="checkbox"]');
            const checked = category.querySelectorAll('input[type="checkbox"]:checked');
            const categoryProgress = Math.round((checked.length / checkboxes.length) * 100);
            
            setCategoryData(exportData.categories, categoryName, {
                progress: categoryProgress,
                completed: checked.length,
                total: checkboxes.length
            });
        });
        
        // Download as JSON
        const blob = new Blob([JSON.stringify(exportData, null, 2)], {type: 'application/json'});
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `best-practices-progress-${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }

    // Reset checklist
    resetChecklist() {
        // eslint-disable-next-line no-alert
        if (confirm('Are you sure you want to reset all checklist items?')) {
            document.querySelectorAll('.checklist-items input[type="checkbox"]').forEach(checkbox => {
                checkbox.checked = false;
            });
            this.updateChecklistProgress();
            this.saveChecklistData();
            this.showProgressNotification();
        }
    }
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOutRight {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.bestPracticesManager = new BestPracticesManager();
});

/**
 * Set category data safely
 */
function setCategoryData(categories, categoryName, data) {
    // Use a safe approach to set category data
    if (categories && typeof categories === 'object') {
        categories[categoryName] = data;
    }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = BestPracticesManager;
}
