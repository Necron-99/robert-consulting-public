#!/usr/bin/env node

/**
 * Generate "Coming Soon" section for blog.html
 * Reads from blog-schedule.json and updates the coming soon section
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SCHEDULE_PATH = path.join(__dirname, '..', 'blog-schedule.json');
const BLOG_HTML_PATH = path.join(__dirname, '..', 'website', 'blog.html');

// Read schedule
function readSchedule() {
  try {
    const content = fs.readFileSync(SCHEDULE_PATH, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`❌ Error reading blog-schedule.json: ${error.message}`);
    process.exit(1);
  }
}

// Format date for display
function formatDate(dateStr) {
  const date = new Date(dateStr + 'T12:00:00');
  const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  return date.toLocaleDateString('en-US', options);
}

// Get day name
function getDayName(dateStr) {
  const date = new Date(dateStr + 'T12:00:00');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[date.getDay()];
}

// Generate coming soon HTML
function generateComingSoonHTML(schedule) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  // Get upcoming approved/proposed topics (next 14 days)
  // Exclude published, generated, or posts that already exist
  const upcoming = schedule.schedule
    .filter(entry => {
      const entryDate = new Date(entry.date + 'T12:00:00');
      entryDate.setHours(0, 0, 0, 0);
      
      // Skip if already published or generated
      if (entry.status === 'published' || entry.status === 'generated') {
        return false;
      }
      
      // Skip if blog post file already exists
      const dayName = entry.day || getDayName(entry.date).toLowerCase();
      const blogPostPath = path.join(__dirname, '..', 'website', 'blog-posts', `${dayName}-${entry.date}.html`);
      if (fs.existsSync(blogPostPath)) {
        return false;
      }
      
      return entryDate >= today && 
             (entry.status === 'approved' || entry.status === 'proposed') &&
             entryDate <= new Date(today.getTime() + 14 * 24 * 60 * 60 * 1000);
    })
    .sort((a, b) => a.date.localeCompare(b.date))
    .slice(0, 10); // Show next 10 topics
  
  if (upcoming.length === 0) {
    return `
    <!-- Coming Soon Section -->
    <section class="coming-soon">
        <div class="container">
            <h2>📅 Coming Soon</h2>
            <p>New blog topics are being planned. Check back soon!</p>
        </div>
    </section>`;
  }
  
  let html = `
    <!-- Coming Soon Section -->
    <section class="coming-soon">
        <div class="container">
            <h2>📅 Coming Soon</h2>
            <p>Upcoming blog posts scheduled for the next two weeks:</p>
            <div class="coming-soon-grid">`;
  
  for (const entry of upcoming) {
    const formattedDate = formatDate(entry.date);
    const dayName = getDayName(entry.date);
    const statusIcon = entry.status === 'approved' ? '✅' : '⏳';
    
    html += `
                <div class="coming-soon-item">
                    <div class="coming-soon-date">
                        <span class="date-icon">${entry.icon || '📝'}</span>
                        <div class="date-info">
                            <span class="date-day">${dayName}</span>
                            <span class="date-full">${formattedDate}</span>
                        </div>
                        <span class="status-badge">${statusIcon}</span>
                    </div>
                    <div class="coming-soon-content">
                        <h3>${entry.topic}</h3>
                        <p>${entry.focus}</p>
                        ${entry.alternatives && entry.alternatives.length > 0 ? 
                          `<div class="alternatives-hint">
                            <small>💡 ${entry.alternatives.length} alternative topic${entry.alternatives.length > 1 ? 's' : ''} available</small>
                          </div>` : ''}
                    </div>
                </div>`;
  }
  
  html += `
            </div>
            <p class="coming-soon-footer">
                <small>Topics are auto-generated weekly. Check back every Sunday for new proposals!</small>
            </p>
        </div>
    </section>`;
  
  return html;
}

// Update blog.html
function updateBlogHTML() {
  const schedule = readSchedule();
  const comingSoonHTML = generateComingSoonHTML(schedule);
  
  let blogHTML = fs.readFileSync(BLOG_HTML_PATH, 'utf8');
  
  // Find and replace the coming soon section
  // Look for existing coming soon section (now a top-level section, not nested)
  const comingSoonRegex = /<!-- Coming Soon Section -->[\s\S]*?<\/section>/;
  const scheduleInfoRegex = /<!-- Blog Schedule Info -->/;
  
  if (comingSoonRegex.test(blogHTML)) {
    // Replace existing section - preserve the structure (top-level section)
    blogHTML = blogHTML.replace(comingSoonRegex, comingSoonHTML.trim());
  } else if (scheduleInfoRegex.test(blogHTML)) {
    // Insert before schedule info (as a top-level section)
    // Find the blog-posts section that contains schedule info
    const beforeSchedule = blogHTML.indexOf('    <!-- Blog Posts (continued for schedule info) -->');
    if (beforeSchedule !== -1) {
      blogHTML = blogHTML.substring(0, beforeSchedule) + 
                 comingSoonHTML.trim() + '\n\n' +
                 blogHTML.substring(beforeSchedule);
    } else {
      // Fallback: insert before schedule info comment
      blogHTML = blogHTML.replace(scheduleInfoRegex, comingSoonHTML.trim() + '\n\n    ' + '<!-- Blog Schedule Info -->');
    }
  } else {
    console.error('❌ Could not find insertion point in blog.html');
    console.error('   Looking for "Coming Soon Section" comment or "Blog Schedule Info" comment');
    process.exit(1);
  }
  
  fs.writeFileSync(BLOG_HTML_PATH, blogHTML, 'utf8');
  
  // Count upcoming topics (excluding published/generated and existing files)
  const upcomingCount = schedule.schedule.filter(e => {
    if (e.status === 'published' || e.status === 'generated') return false;
    const dayName = e.day || getDayName(e.date).toLowerCase();
    const blogPostPath = path.join(__dirname, '..', 'website', 'blog-posts', `${dayName}-${e.date}.html`);
    if (fs.existsSync(blogPostPath)) return false;
    const entryDate = new Date(e.date + 'T12:00:00');
    entryDate.setHours(0, 0, 0, 0);
    return entryDate >= new Date() && (e.status === 'approved' || e.status === 'proposed');
  }).length;
  
  console.log(`✅ Updated coming soon section in blog.html with ${upcomingCount} upcoming topics`);
}

// Main
updateBlogHTML();

