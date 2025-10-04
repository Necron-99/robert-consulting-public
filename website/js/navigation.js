// Standardized Navigation JavaScript

document.addEventListener('DOMContentLoaded', function() {
  const hamburger = document.getElementById('hamburger');
  const navMenu = document.getElementById('nav-menu');
  const navLinks = document.querySelectorAll('.nav-link');
  
  // Mobile menu toggle
  if (hamburger && navMenu) {
    hamburger.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      hamburger.classList.toggle('active');
      navMenu.classList.toggle('active');
      
      // Prevent body scroll when menu is open
      if (navMenu.classList.contains('active')) {
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
      }
    });
  }
  
  // Close mobile menu when clicking on a link
  navLinks.forEach(link => {
    link.addEventListener('click', function() {
      if (navMenu.classList.contains('active')) {
        hamburger.classList.remove('active');
        navMenu.classList.remove('active');
        document.body.style.overflow = '';
      }
    });
  });
  
  // Close mobile menu when clicking outside
  document.addEventListener('click', function(event) {
    const isClickInsideNav = navMenu.contains(event.target);
    const isClickOnHamburger = hamburger.contains(event.target);
    
    if (!isClickInsideNav && !isClickOnHamburger && navMenu.classList.contains('active')) {
      hamburger.classList.remove('active');
      navMenu.classList.remove('active');
      document.body.style.overflow = '';
    }
  });
  
  // Set active navigation link based on current page
  setActiveNavLink();
  
  // Handle navigation scroll behavior
  handleNavScroll();
});

// Set active navigation link
function setActiveNavLink() {
  const currentPage = window.location.pathname.split('/').pop();
  const navLinks = document.querySelectorAll('.nav-link');
  
  navLinks.forEach(link => {
    const href = link.getAttribute('href');
    
    // Remove active class from all links
    link.classList.remove('active');
    
    // Add active class to current page link
    if (href === currentPage || 
        (currentPage === '' && href === 'index.html') ||
        (currentPage === 'index.html' && href === 'index.html#home')) {
      link.classList.add('active');
    }
  });
}

// Handle navigation scroll behavior
function handleNavScroll() {
  const navbar = document.querySelector('.navbar');
  let lastScrollTop = 0;
  
  if (navbar) {
    window.addEventListener('scroll', function() {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      
      // Hide navbar when scrolling down, show when scrolling up
      if (scrollTop > lastScrollTop && scrollTop > 100) {
        navbar.classList.add('nav-hidden');
      } else {
        navbar.classList.remove('nav-hidden');
      }
      
      lastScrollTop = scrollTop;
    });
  }
}

// Smooth scroll for anchor links
document.addEventListener('click', function(event) {
  if (event.target.matches('a[href^="#"]')) {
    event.preventDefault();
    
    const targetId = event.target.getAttribute('href').substring(1);
    const targetElement = document.getElementById(targetId);
    
    if (targetElement) {
      const navbarHeight = document.querySelector('.navbar').offsetHeight;
      const targetPosition = targetElement.offsetTop - navbarHeight - 20;
      
      window.scrollTo({
        top: targetPosition,
        behavior: 'smooth'
      });
    }
  }
});

// Handle keyboard navigation
document.addEventListener('keydown', function(event) {
  const navMenu = document.getElementById('nav-menu');
  const hamburger = document.getElementById('hamburger');
  
  // Close mobile menu with Escape key
  if (event.key === 'Escape' && navMenu.classList.contains('active')) {
    hamburger.classList.remove('active');
    navMenu.classList.remove('active');
    document.body.style.overflow = '';
  }
});

// Handle focus management for accessibility
document.addEventListener('keydown', function(event) {
  const navMenu = document.getElementById('nav-menu');
  const navLinks = document.querySelectorAll('.nav-link');
  
  if (navMenu.classList.contains('active')) {
    const firstLink = navLinks[0];
    const lastLink = navLinks[navLinks.length - 1];
    
    if (event.key === 'Tab') {
      if (event.shiftKey) {
        // Shift + Tab (backward)
        if (document.activeElement === firstLink) {
          event.preventDefault();
          hamburger.focus();
        }
      } else {
        // Tab (forward)
        if (document.activeElement === lastLink) {
          event.preventDefault();
          hamburger.focus();
        }
      }
    }
  }
});

// Handle window resize
window.addEventListener('resize', function() {
  const navMenu = document.getElementById('nav-menu');
  const hamburger = document.getElementById('hamburger');
  
  // Close mobile menu on window resize
  if (window.innerWidth > 768 && navMenu.classList.contains('active')) {
    hamburger.classList.remove('active');
    navMenu.classList.remove('active');
    document.body.style.overflow = '';
  }
});

// Export functions for external use
window.Navigation = {
  setActiveNavLink,
  handleNavScroll
};
