// Bailey Lessons Website JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Mobile menu toggle
    const mobileMenuBtn = document.createElement('button');
    mobileMenuBtn.innerHTML = '<i class="fas fa-bars"></i>';
    mobileMenuBtn.className = 'mobile-menu';
    mobileMenuBtn.style.cssText = `
        display: none;
        background: none;
        border: none;
        font-size: 1.5rem;
        color: #333;
        cursor: pointer;
    `;
    
    if (window.innerWidth <= 768) {
        mobileMenuBtn.style.display = 'block';
        document.querySelector('nav').appendChild(mobileMenuBtn);
    }
    
    // Mobile menu functionality
    const navLinks = document.querySelector('.nav-links');
    mobileMenuBtn.addEventListener('click', function() {
        navLinks.classList.toggle('active');
    });
    
    // Close mobile menu when clicking on a link
    document.querySelectorAll('.nav-links a').forEach(link => {
        link.addEventListener('click', function() {
            navLinks.classList.remove('active');
        });
    });
    
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                const headerHeight = document.querySelector('header').offsetHeight;
                const targetPosition = target.offsetTop - headerHeight;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Scroll to top button
    const scrollToTopBtn = document.createElement('button');
    scrollToTopBtn.innerHTML = '<i class="fas fa-arrow-up"></i>';
    scrollToTopBtn.className = 'scroll-to-top';
    document.body.appendChild(scrollToTopBtn);
    
    // Show/hide scroll to top button
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            scrollToTopBtn.classList.add('visible');
        } else {
            scrollToTopBtn.classList.remove('visible');
        }
    });
    
    // Scroll to top functionality
    scrollToTopBtn.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
    
    // FAQ functionality
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');
        
        question.addEventListener('click', function() {
            // Close other FAQ items
            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.querySelector('.faq-answer').classList.remove('active');
                }
            });
            
            // Toggle current FAQ item
            answer.classList.toggle('active');
        });
    });
    
    // Form submission with validation
    const contactForm = document.querySelector('form');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = new FormData(contactForm);
            const name = formData.get('name');
            const email = formData.get('email');
            const subject = formData.get('subject');
            const message = formData.get('message');
            
            // Basic validation
            if (!name || !email || !subject || !message) {
                showMessage('Please fill in all fields.', 'error');
                return;
            }
            
            if (!isValidEmail(email)) {
                showMessage('Please enter a valid email address.', 'error');
                return;
            }
            
            // Show loading state
            const submitBtn = contactForm.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.textContent = 'Sending...';
            submitBtn.disabled = true;
            
            // Simulate form submission (replace with actual form handling)
            setTimeout(() => {
                showMessage('Thank you for your message! I will get back to you soon.', 'success');
                contactForm.reset();
                submitBtn.textContent = originalText;
                submitBtn.disabled = false;
            }, 2000);
        });
    }
    
    // Email validation function
    function isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }
    
    // Show message function
    function showMessage(text, type) {
        // Remove existing messages
        const existingMessages = document.querySelectorAll('.message');
        existingMessages.forEach(msg => msg.remove());
        
        // Create new message
        const message = document.createElement('div');
        message.className = `message ${type}`;
        message.textContent = text;
        
        // Insert message before form
        contactForm.parentNode.insertBefore(message, contactForm);
        
        // Auto-hide success messages
        if (type === 'success') {
            setTimeout(() => {
                message.remove();
            }, 5000);
        }
    }
    
    // Intersection Observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-up');
            }
        });
    }, observerOptions);
    
    // Observe elements for animation
    document.querySelectorAll('.service-card, .testimonial-card, .pricing-card').forEach(el => {
        observer.observe(el);
    });
    
    // Header background on scroll
    const header = document.querySelector('header');
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 100) {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.backdropFilter = 'blur(10px)';
        } else {
            header.style.background = '#fff';
            header.style.backdropFilter = 'none';
        }
    });
    
    // Add testimonials section if it doesn't exist
    if (!document.querySelector('.testimonials')) {
        const servicesSection = document.querySelector('.services');
        const testimonialsHTML = `
            <section class="testimonials">
                <div class="container">
                    <h2 class="section-title">What Students & Parents Say</h2>
                    <div class="testimonials-grid">
                        <div class="testimonial-card">
                            <div class="testimonial-text">
                                Megan has offered personalized and superlative services to our daughter in mathematics tutoring. 
                                Not only has her performance markedly improved but, more importantly, so has her confidence!
                            </div>
                            <div class="testimonial-author">- Paul L., Parent</div>
                        </div>
                        <div class="testimonial-card">
                            <div class="testimonial-text">
                                The personalized approach and engaging lessons have made a huge difference in my understanding of chemistry. 
                                I went from struggling to excelling in just a few months!
                            </div>
                            <div class="testimonial-author">- Sarah M., Student</div>
                        </div>
                        <div class="testimonial-card">
                            <div class="testimonial-text">
                                Megan's expertise in physics helped me not only understand the concepts but also develop a genuine interest in the subject. 
                                Highly recommended!
                            </div>
                            <div class="testimonial-author">- Alex K., Student</div>
                        </div>
                    </div>
                </div>
            </section>
        `;
        servicesSection.insertAdjacentHTML('afterend', testimonialsHTML);
    }
    
    // Add FAQ section
    const aboutSection = document.querySelector('.about');
    const faqHTML = `
        <section class="faq">
            <div class="container">
                <h2 class="section-title">Frequently Asked Questions</h2>
                <div class="faq-item">
                    <div class="faq-question">
                        <span>What subjects do you tutor?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        I specialize in math (elementary through algebra 2, geometry, personal finance) and science (biology, chemistry, physics) for elementary through college level students.
                    </div>
                </div>
                <div class="faq-item">
                    <div class="faq-question">
                        <span>Do you offer online tutoring?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        Yes! I offer Zoom sessions for the same quality instruction you'd get in person. All you need is a computer or tablet with internet connection.
                    </div>
                </div>
                <div class="faq-item">
                    <div class="faq-question">
                        <span>How long are the tutoring sessions?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        Each session is 45 minutes long, which provides enough time for focused learning while keeping students engaged and attentive.
                    </div>
                </div>
                <div class="faq-item">
                    <div class="faq-question">
                        <span>What is your experience level?</span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                    <div class="faq-answer">
                        I have over 20 years of experience in math and science education, working with students of all ages and learning styles to achieve academic success.
                    </div>
                </div>
            </div>
        </section>
    `;
    aboutSection.insertAdjacentHTML('afterend', faqHTML);
    
    // Re-observe new elements
    document.querySelectorAll('.testimonial-card').forEach(el => {
        observer.observe(el);
    });
});

// Utility functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Resize handler
window.addEventListener('resize', debounce(function() {
    const mobileMenuBtn = document.querySelector('.mobile-menu');
    if (window.innerWidth > 768) {
        if (mobileMenuBtn) {
            mobileMenuBtn.style.display = 'none';
        }
        document.querySelector('.nav-links').classList.remove('active');
    } else {
        if (mobileMenuBtn) {
            mobileMenuBtn.style.display = 'block';
        }
    }
}, 250));
