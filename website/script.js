// Mobile Navigation Toggle
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');

hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navMenu.classList.toggle('active');
});

// Close mobile menu when clicking on a link
document.querySelectorAll('.nav-link').forEach(n => n.addEventListener('click', () => {
    hamburger.classList.remove('active');
    navMenu.classList.remove('active');
}));

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
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

// Navbar background change on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.background = 'rgba(255, 255, 255, 0.98)';
        navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        navbar.style.boxShadow = 'none';
    }
});

// Contact form handling
const contactForm = document.querySelector('.contact-form');
if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Get form data
        const formData = new FormData(this);
        const name = formData.get('name');
        const email = formData.get('email');
        const subject = formData.get('subject');
        const message = formData.get('message');
        
        // Simple validation
        if (!name || !email || !subject || !message) {
            alert('Please fill in all fields.');
            return;
        }
        
        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            alert('Please enter a valid email address.');
            return;
        }
        
        // Simulate form submission
        const submitBtn = this.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        
        submitBtn.textContent = 'Sending...';
        submitBtn.disabled = true;
        
        // Simulate API call
        setTimeout(() => {
            alert('Thank you for your message! I\'ll get back to you soon.');
            this.reset();
            submitBtn.textContent = originalText;
            submitBtn.disabled = false;
            
            // Track form submission for analytics
            trackFormSubmission(name, email, subject);
        }, 2000);
    });
}

// Analytics tracking functions
function trackFormSubmission(name, email, subject) {
    // Store form submission data
    const formData = {
        name: name,
        email: email,
        subject: subject,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        referrer: document.referrer
    };
    
    // Store in localStorage for admin dashboard
    const submissions = JSON.parse(localStorage.getItem('form_submissions') || '[]');
    submissions.push(formData);
    localStorage.setItem('form_submissions', JSON.stringify(submissions));
    
    // Update dashboard if available
    if (window.dashboard) {
        window.dashboard.addActivity('contact', `New inquiry from ${email}`);
    }
    
    console.log('Form submission tracked:', formData);
}

function trackPageView() {
    const pageView = {
        timestamp: new Date().toISOString(),
        url: window.location.href,
        userAgent: navigator.userAgent,
        referrer: document.referrer,
        screenResolution: `${screen.width}x${screen.height}`,
        language: navigator.language
    };
    
    // Store in localStorage for admin dashboard
    const pageViews = JSON.parse(localStorage.getItem('page_views') || '[]');
    pageViews.push(pageView);
    localStorage.setItem('page_views', JSON.stringify(pageViews));
    
    // Update dashboard if available
    if (window.dashboard) {
        window.dashboard.addActivity('visitor', `Visitor from ${navigator.language}`);
    }
    
    console.log('Page view tracked:', pageView);
}

// Track page view on load
document.addEventListener('DOMContentLoaded', () => {
    trackPageView();
});

// Optimized: Simplified intersection observer for cost efficiency
const observerOptions = {
    threshold: 0.2,
    rootMargin: '0px 0px -20px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
            observer.unobserve(entry.target); // Stop observing after animation
        }
    });
}, observerOptions);

// Observe elements for animation (reduced scope for performance)
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.service-card');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.4s ease, transform 0.4s ease';
        observer.observe(el);
    });
});

// Add loading animation for images
document.addEventListener('DOMContentLoaded', () => {
    const images = document.querySelectorAll('img');
    images.forEach(img => {
        img.addEventListener('load', () => {
            img.style.opacity = '1';
        });
    });
});

// Add hover effects for service cards
document.addEventListener('DOMContentLoaded', () => {
    const serviceCards = document.querySelectorAll('.service-card');
    
    serviceCards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-10px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0) scale(1)';
        });
    });
});

// Version management and display
document.addEventListener('DOMContentLoaded', () => {
    // Load version information
    fetch('version.json')
        .then(response => response.json())
        .then(data => {
            const versionDisplay = document.getElementById('version-display');
            const buildDisplay = document.getElementById('build-display');
            
            if (versionDisplay) {
                versionDisplay.textContent = `v${data.version}`;
            }
            
            if (buildDisplay) {
                buildDisplay.textContent = `Build ${data.build}`;
            }
            
            // Add version info to console for debugging
            console.log(`Robert Bailey Consulting Website v${data.version} (${data.build})`);
        })
        .catch(error => {
            console.warn('Could not load version information:', error);
        });
});

// Optimized: Removed typing effect and scroll progress for cost optimization
// These features consume more bandwidth and processing power
