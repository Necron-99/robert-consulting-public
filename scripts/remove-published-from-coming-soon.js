#!/usr/bin/env node

/**
 * Remove published blog posts from coming soon section
 * This script checks for published posts and updates the coming soon section
 * Can be run manually or as part of the blog generation workflow
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SCHEDULE_PATH = path.join(__dirname, '..', 'blog-schedule.json');
const BLOG_POSTS_DIR = path.join(__dirname, '..', 'website', 'blog-posts');

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

// Get day name from date
function getDayName(dateStr) {
  const date = new Date(dateStr + 'T12:00:00');
  const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  return days[date.getDay()];
}

// Check if blog post file exists
function blogPostExists(date, day) {
  const dayName = day || getDayName(date);
  const blogPostPath = path.join(BLOG_POSTS_DIR, `${dayName}-${date}.html`);
  return fs.existsSync(blogPostPath);
}

// Update schedule to mark published posts
function updatePublishedStatus() {
  const schedule = readSchedule();
  let updated = 0;
  
  schedule.schedule.forEach(entry => {
    // If post exists but status isn't published, update it
    if (blogPostExists(entry.date, entry.day) && 
        entry.status !== 'published' && 
        entry.status !== 'generated') {
      console.log(`📝 Marking ${entry.date} (${entry.topic}) as published`);
      entry.status = 'published';
      entry.publishedAt = new Date().toISOString();
      updated++;
    }
  });
  
  if (updated > 0) {
    fs.writeFileSync(SCHEDULE_PATH, JSON.stringify(schedule, null, 2), 'utf8');
    console.log(`✅ Updated ${updated} entries to published status`);
  } else {
    console.log(`ℹ️  No entries needed updating`);
  }
  
  return updated > 0;
}

// Main
if (import.meta.url === `file://${process.argv[1]}`) {
  const changed = updatePublishedStatus();
  if (changed) {
    console.log('\n🔄 Run "node scripts/generate-coming-soon.js" to update the coming soon section');
  }
}

export { updatePublishedStatus, blogPostExists };

