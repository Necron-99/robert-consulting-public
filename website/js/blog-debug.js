/**
 * Blog Page Debugging and Diagnostics
 * Logs information about page structure, CSS, and potential issues
 */

(function() {
  'use strict';

  function logSectionDiagnostics() {
    console.group('🔍 Blog Page Diagnostics');
    
    // Check if coming soon section exists in DOM
    const comingSoonSection = document.querySelector('.coming-soon');
    if (comingSoonSection) {
      console.log('✅ Coming Soon section found in DOM');
      
      // Check computed styles
      const computedStyle = window.getComputedStyle(comingSoonSection);
      console.log('📊 Computed Styles:', {
        display: computedStyle.display,
        visibility: computedStyle.visibility,
        opacity: computedStyle.opacity,
        height: computedStyle.height,
        minHeight: computedStyle.minHeight,
        marginTop: computedStyle.marginTop,
        padding: computedStyle.padding,
        position: computedStyle.position,
        zIndex: computedStyle.zIndex
      });
      
      // Check if section is visible
      const isVisible = comingSoonSection.offsetHeight > 0 && 
                       computedStyle.display !== 'none' && 
                       computedStyle.visibility !== 'hidden' &&
                       parseFloat(computedStyle.opacity) > 0;
      
      console.log('👁️ Section Visibility:', isVisible ? 'VISIBLE' : 'HIDDEN');
      
      // Check content
      const items = comingSoonSection.querySelectorAll('.coming-soon-item');
      console.log(`📦 Coming Soon Items: ${items.length} found`);
      
      if (items.length === 0) {
        console.warn('⚠️ WARNING: Coming soon section exists but has no items!');
      }
      
      // Check parent elements
      let parent = comingSoonSection.parentElement;
      let depth = 0;
      while (parent && depth < 5) {
        const parentStyle = window.getComputedStyle(parent);
        if (parentStyle.display === 'none' || parentStyle.visibility === 'hidden') {
          console.error(`❌ Parent element (${parent.tagName}.${parent.className}) is hiding the section!`);
        }
        parent = parent.parentElement;
        depth++;
      }
      
    } else {
      console.error('❌ Coming Soon section NOT FOUND in DOM!');
      console.log('🔍 Searching for similar elements...');
      
      // Search for any section with "coming" in class or id
      const allSections = document.querySelectorAll('section');
      console.log(`Found ${allSections.length} sections on page`);
      allSections.forEach((section, index) => {
        if (section.className.includes('coming') || section.id.includes('coming')) {
          console.log(`  Section ${index}:`, section.className, section.id);
        }
      });
    }
    
    // Check CSS file loading
    const cssLinks = Array.from(document.querySelectorAll('link[rel="stylesheet"]'));
    const blogCss = cssLinks.find(link => link.href.includes('blog.css'));
    if (blogCss) {
      console.log('✅ blog.css is loaded:', blogCss.href);
    } else {
      console.error('❌ blog.css NOT FOUND in loaded stylesheets!');
    }
    
    // Check for JavaScript errors
    window.addEventListener('error', (event) => {
      console.error('🚨 JavaScript Error:', event.message, event.filename, event.lineno);
    });
    
    // Check blog grid
    const blogGrid = document.getElementById('blog-grid');
    if (blogGrid) {
      console.log('✅ Blog grid found');
      const gridRect = blogGrid.getBoundingClientRect();
      console.log('📐 Blog grid position:', {
        top: gridRect.top,
        bottom: gridRect.bottom,
        height: gridRect.height
      });
    } else {
      console.error('❌ Blog grid NOT FOUND!');
    }
    
    // Check schedule info
    const scheduleInfo = document.querySelector('.blog-schedule-info');
    if (scheduleInfo) {
      console.log('✅ Schedule info found');
      const scheduleRect = scheduleInfo.getBoundingClientRect();
      console.log('📐 Schedule info position:', {
        top: scheduleRect.top,
        bottom: scheduleRect.bottom
      });
    }
    
    console.groupEnd();
  }

  // Run diagnostics when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(logSectionDiagnostics, 100); // Small delay to ensure all scripts run
    });
  } else {
    setTimeout(logSectionDiagnostics, 100);
  }

  // Also run after a short delay to catch any dynamic changes
  setTimeout(logSectionDiagnostics, 1000);
  
  // Expose diagnostic function globally for manual testing
  window.debugBlogPage = logSectionDiagnostics;
  
  console.log('🔧 Blog debug script loaded. Run window.debugBlogPage() to check diagnostics.');
})();

