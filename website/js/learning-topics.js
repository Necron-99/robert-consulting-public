// Simple Learning Topics JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Learning topics script loaded');
    
    const topics = [
        {
            id: 'html5',
            title: 'HTML5',
            description: 'Semantic markup, accessibility, and modern web standards',
            category: 'technologies',
            icon: '🌐',
            tags: ['frontend', 'html', 'web-standards'],
            difficulty: 'Beginner'
        },
        {
            id: 'css3',
            title: 'CSS3',
            description: 'Responsive design, animations, and modern layout techniques',
            category: 'technologies',
            icon: '🎨',
            tags: ['frontend', 'css', 'design'],
            difficulty: 'Beginner'
        },
        {
            id: 'javascript',
            title: 'JavaScript ES6+',
            description: 'Modern JavaScript, async programming, and DOM manipulation',
            category: 'technologies',
            icon: '⚡',
            tags: ['frontend', 'javascript', 'programming'],
            difficulty: 'Intermediate'
        },
        {
            id: 'aws',
            title: 'AWS Services',
            description: 'S3, CloudFront, Route 53, IAM, and cost optimization',
            category: 'technologies',
            icon: '☁️',
            tags: ['cloud', 'aws', 'infrastructure'],
            difficulty: 'Intermediate'
        },
        {
            id: 'terraform',
            title: 'Terraform',
            description: 'Infrastructure as Code, state management, and automation',
            category: 'technologies',
            icon: '🏗️',
            tags: ['infrastructure', 'terraform', 'iac'],
            difficulty: 'Intermediate'
        },
        {
            id: 'security',
            title: 'Security',
            description: 'HTTPS, CSP headers, authentication, and best practices',
            category: 'technologies',
            icon: '🔒',
            tags: ['security', 'authentication', 'https'],
            difficulty: 'Advanced'
        }
    ];
    
    let filteredTopics = topics;
    let currentFilter = 'all';
    
    function renderTopics() {
        const grid = document.getElementById('topics-grid');
        if (!grid) {
            console.log('Grid not found');
            return;
        }
        
        grid.innerHTML = '';
        
        filteredTopics.forEach(topic => {
            const card = document.createElement('div');
            card.className = 'topic-card';
            card.innerHTML = `
                <span class="topic-icon">${topic.icon}</span>
                <h3>${topic.title}</h3>
                <p>${topic.description}</p>
                <div class="topic-tags">
                    ${topic.tags.map(tag => `<span class="topic-tag">${tag}</span>`).join('')}
                </div>
                <div class="topic-meta">
                    <span class="topic-category">TECHNOLOGY</span>
                    <span class="topic-difficulty">${topic.difficulty}</span>
                </div>
            `;
            grid.appendChild(card);
        });
        
        updateStats();
    }
    
    function updateStats() {
        const statsElement = document.getElementById('topic-count');
        if (statsElement) {
            statsElement.textContent = `Showing ${filteredTopics.length} of ${topics.length} topics`;
        }
    }
    
    function filterTopics() {
        const searchInput = document.getElementById('topic-search');
        const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
        
        filteredTopics = topics.filter(topic => {
            const matchesSearch = topic.title.toLowerCase().includes(searchTerm) ||
                                 topic.description.toLowerCase().includes(searchTerm) ||
                                 topic.tags.some(tag => tag.toLowerCase().includes(searchTerm));
            
            const matchesFilter = currentFilter === 'all' || topic.category === currentFilter;
            
            return matchesSearch && matchesFilter;
        });
        
        renderTopics();
    }
    
    // Setup event listeners
    const searchInput = document.getElementById('topic-search');
    if (searchInput) {
        searchInput.addEventListener('input', filterTopics);
    }
    
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            // Remove active class from all buttons
            filterButtons.forEach(b => b.classList.remove('active'));
            // Add active class to clicked button
            this.classList.add('active');
            
            currentFilter = this.dataset.filter;
            filterTopics();
        });
    });
    
    // Initial render
    renderTopics();
});
