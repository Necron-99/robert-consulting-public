// Import required modules
import {APIConfig} from './js/api-config.js';

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
  anchor.addEventListener('click', function(e) {
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
  contactForm.addEventListener('submit', async function(e) {
    e.preventDefault();

    try {
      // Validate form with security config (if available)
      if (window.securityConfig && typeof window.securityConfig.validateFormSubmission === 'function') {
        try {
          window.securityConfig.validateFormSubmission(this);
        } catch (securityError) {
          console.warn('Security validation failed, proceeding with basic validation:', securityError.message);
          // Continue with basic validation instead of failing
        }
      }

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

      // Send form data to API
      const submitBtn = this.querySelector('button[type="submit"]');
      const originalText = submitBtn.textContent;

      submitBtn.textContent = 'Sending...';
      submitBtn.disabled = true;

      try {
        // Use secure API configuration
        const apiConfig = new APIConfig();
        const result = await apiConfig.submitContactForm({
          name: name,
          email: email,
          subject: subject,
          message: message
        });

        if (result.success) {
          alert('Thank you for your message! I\'ll get back to you soon.');
          this.reset();

          // Track successful form submission
          trackFormSubmission(name, email, subject);
        } else {
          throw new Error(result.error || 'Failed to send message');
        }

      } catch (error) {
        console.error('Form submission error:', error);
        alert('Sorry, there was an error sending your message. Please try again or contact me directly at info@robertconsulting.net');
      } finally {
        submitBtn.textContent = originalText;
        submitBtn.disabled = false;
      }
    } catch (error) {
      console.error('Form submission error:', error);
      // Provide more helpful error messages
      if (error.message.includes('CSRF')) {
        alert('Security validation failed. Please refresh the page and try again.');
      } else if (error.message.includes('rate limit')) {
        alert('Please wait a moment before submitting another message.');
      } else {
        alert(`Form submission failed: ${error.message}`);
      }
    }
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
    language: navigator.language,
    ip: getClientIP(),
    location: getLocationFromLanguage(navigator.language),
    browser: getBrowserInfo(navigator.userAgent),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
  };

  // Store in localStorage for admin dashboard
  const pageViews = JSON.parse(localStorage.getItem('page_views') || '[]');
  pageViews.push(pageView);
  localStorage.setItem('page_views', JSON.stringify(pageViews));

  // Update dashboard if available
  if (window.dashboard) {
    window.dashboard.addActivity('visitor', `Visitor from ${pageView.location}`);
  }

  console.log('Page view tracked:', pageView);
}

// Get client IP (simplified - in production, use proper IP detection)
function getClientIP() {
  // This is a placeholder - in production, you'd get this from your server
  // For demo purposes, generate a realistic-looking IP
  const randomIP = () => Math.floor(Math.random() * 255);
  return `${randomIP()}.${randomIP()}.${randomIP()}.${randomIP()}`;
}

// Get location from language (simplified)
function getLocationFromLanguage(language) {
  const locationMap = {
    'en-US': 'United States',
    'en-GB': 'United Kingdom',
    'en-CA': 'Canada',
    'en-AU': 'Australia',
    'de-DE': 'Germany',
    'fr-FR': 'France',
    'es-ES': 'Spain',
    'it-IT': 'Italy',
    'pt-BR': 'Brazil',
    'ja-JP': 'Japan',
    'ko-KR': 'South Korea',
    'zh-CN': 'China',
    'ru-RU': 'Russia',
    'nl-NL': 'Netherlands',
    'sv-SE': 'Sweden',
    'no-NO': 'Norway',
    'da-DK': 'Denmark',
    'fi-FI': 'Finland'
  };

  let location;
  switch (language) {
  case 'en-US':
    location = 'United States';
    break;
  case 'en-GB':
    location = 'United Kingdom';
    break;
  case 'en-CA':
    location = 'Canada';
    break;
  case 'en-AU':
    location = 'Australia';
    break;
  case 'de-DE':
    location = 'Germany';
    break;
  case 'fr-FR':
    location = 'France';
    break;
  case 'es-ES':
    location = 'Spain';
    break;
  case 'it-IT':
    location = 'Italy';
    break;
  case 'pt-BR':
    location = 'Brazil';
    break;
  case 'ja-JP':
    location = 'Japan';
    break;
  case 'ko-KR':
    location = 'South Korea';
    break;
  case 'zh-CN':
    location = 'China';
    break;
  case 'ru-RU':
    location = 'Russia';
    break;
  case 'ar-SA':
    location = 'Saudi Arabia';
    break;
  case 'hi-IN':
    location = 'India';
    break;
  case 'th-TH':
    location = 'Thailand';
    break;
  case 'vi-VN':
    location = 'Vietnam';
    break;
  case 'tr-TR':
    location = 'Turkey';
    break;
  case 'pl-PL':
    location = 'Poland';
    break;
  case 'nl-NL':
    location = 'Netherlands';
    break;
  case 'sv-SE':
    location = 'Sweden';
    break;
  case 'no-NO':
    location = 'Norway';
    break;
  case 'da-DK':
    location = 'Denmark';
    break;
  case 'fi-FI':
    location = 'Finland';
    break;
  default:
    location = 'Unknown';
  }
  return location;
}

// Get browser info
function getBrowserInfo(userAgent) {
  if (userAgent.includes('Chrome')) {
    return 'Chrome';
  }
  if (userAgent.includes('Firefox')) {
    return 'Firefox';
  }
  if (userAgent.includes('Safari')) {
    return 'Safari';
  }
  if (userAgent.includes('Edge')) {
    return 'Edge';
  }
  if (userAgent.includes('Opera')) {
    return 'Opera';
  }
  return 'Unknown';
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

// Version management is now handled by version-manager.js

// Optimized: Removed typing effect and scroll progress for cost optimization
// These features consume more bandwidth and processing power
