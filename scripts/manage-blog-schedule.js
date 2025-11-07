#!/usr/bin/env node

/**
 * Blog Schedule Management CLI
 * Manage blog topic proposals, approvals, and scheduling
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SCHEDULE_PATH = path.join(__dirname, '..', 'blog-schedule.json');

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

// Write schedule
function writeSchedule(schedule) {
  schedule.lastUpdated = new Date().toISOString();
  fs.writeFileSync(SCHEDULE_PATH, JSON.stringify(schedule, null, 2) + '\n');
  console.log('✅ Schedule updated');
}

// Find entry by date
function findEntry(schedule, date) {
  return schedule.schedule.findIndex(s => s.date === date);
}

// View schedule
function viewSchedule(days = 14) {
  const schedule = readSchedule();
  const today = new Date();
  const futureDate = new Date(today);
  futureDate.setDate(futureDate.getDate() + days);
  
  const upcoming = schedule.schedule
    .filter(s => {
      const entryDate = new Date(s.date);
      return entryDate >= today && entryDate <= futureDate;
    })
    .sort((a, b) => a.date.localeCompare(b.date));
  
  if (upcoming.length === 0) {
    console.log(`📅 No scheduled topics for next ${days} days`);
    return;
  }
  
  console.log(`\n📅 Upcoming Blog Schedule (next ${days} days):\n`);
  
  for (const entry of upcoming) {
    const statusIcon = {
      'proposed': '⏳',
      'approved': '✅',
      'generated': '📝',
      'skipped': '⏭️'
    }[entry.status] || '❓';
    
    console.log(`${statusIcon} ${entry.date} (${entry.day})`);
    console.log(`   Topic: ${entry.topic}`);
    console.log(`   Focus: ${entry.focus}`);
    console.log(`   Status: ${entry.status}`);
    if (entry.researchNotes) {
      console.log(`   Research: ${entry.researchNotes}`);
    }
    if (entry.alternatives && entry.alternatives.length > 0) {
      console.log(`   Alternatives: ${entry.alternatives.length} options`);
    }
    console.log('');
  }
}

// Approve topic
function approveTopic(date) {
  const schedule = readSchedule();
  const index = findEntry(schedule, date);
  
  if (index === -1) {
    console.error(`❌ No topic found for date ${date}`);
    process.exit(1);
  }
  
  schedule.schedule[index].status = 'approved';
  schedule.schedule[index].approvedBy = 'user';
  schedule.schedule[index].approvedAt = new Date().toISOString();
  
  writeSchedule(schedule);
  console.log(`✅ Approved topic for ${date}: ${schedule.schedule[index].topic}`);
}

// Edit topic
function editTopic(date, options) {
  const schedule = readSchedule();
  const index = findEntry(schedule, date);
  
  if (index === -1) {
    console.error(`❌ No topic found for date ${date}`);
    process.exit(1);
  }
  
  const entry = schedule.schedule[index];
  
  if (options.topic) entry.topic = options.topic;
  if (options.focus) entry.focus = options.focus;
  if (options.keywords) entry.keywords = options.keywords;
  if (options.notes) entry.notes = options.notes;
  
  writeSchedule(schedule);
  console.log(`✅ Updated topic for ${date}`);
}

// Suggest topic
function suggestTopic(date, options) {
  const schedule = readSchedule();
  const dateObj = new Date(date + 'T12:00:00'); // Add time to avoid timezone issues
  const dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const dayName = dayNames[dateObj.getDay()];
  
  if (!['monday', 'tuesday', 'wednesday', 'thursday', 'friday'].includes(dayName)) {
    console.error(`❌ Date ${date} is not a weekday (it's ${dayName})`);
    process.exit(1);
  }
  
  // Get category metadata
  const categoryMap = {
    monday: { category: 'aws', icon: '☁️', tags: ['AWS', 'Cloud Infrastructure'] },
    tuesday: { category: 'devops', icon: '⚙️', tags: ['DevOps', 'Automation'] },
    wednesday: { category: 'security', icon: '🔒', tags: ['Security', 'DevSecOps'] },
    thursday: { category: 'infrastructure', icon: '🏗️', tags: ['Infrastructure as Code', 'IaC'] },
    friday: { category: 'containers', icon: '🐳', tags: ['Kubernetes', 'Docker'] }
  };
  
  const metadata = categoryMap[dayName];
  
  const entry = {
    date: date,
    day: dayName,
    status: 'approved',
    topic: options.topic,
    focus: options.focus || '',
    keywords: options.keywords || '',
    category: metadata.category,
    icon: metadata.icon,
    tags: metadata.tags,
    readTime: "10 min read",
    notes: options.notes || '',
    researchNotes: '',
    suggestedBy: 'user',
    suggestedAt: new Date().toISOString(),
    approvedBy: 'user',
    approvedAt: new Date().toISOString(),
    alternatives: []
  };
  
  const index = findEntry(schedule, date);
  if (index >= 0) {
    schedule.schedule[index] = entry;
  } else {
    schedule.schedule.push(entry);
  }
  
  schedule.schedule.sort((a, b) => a.date.localeCompare(b.date));
  writeSchedule(schedule);
  console.log(`✅ Added topic for ${date}: ${options.topic}`);
}

// Add research notes
function addResearch(date, filePath) {
  const schedule = readSchedule();
  const index = findEntry(schedule, date);
  
  if (index === -1) {
    console.error(`❌ No topic found for date ${date}`);
    process.exit(1);
  }
  
  // Validate file exists
  const fullPath = path.isAbsolute(filePath) ? filePath : path.join(__dirname, '..', filePath);
  if (!fs.existsSync(fullPath)) {
    console.error(`❌ Research file not found: ${fullPath}`);
    process.exit(1);
  }
  
  schedule.schedule[index].researchNotes = filePath;
  writeSchedule(schedule);
  console.log(`✅ Added research notes for ${date}: ${filePath}`);
}

// Switch to alternative
function switchAlternative(date, altIndex) {
  const schedule = readSchedule();
  const index = findEntry(schedule, date);
  
  if (index === -1) {
    console.error(`❌ No topic found for date ${date}`);
    process.exit(1);
  }
  
  const entry = schedule.schedule[index];
  if (!entry.alternatives || entry.alternatives.length === 0) {
    console.error(`❌ No alternatives available for ${date}`);
    process.exit(1);
  }
  
  if (altIndex < 1 || altIndex > entry.alternatives.length) {
    console.error(`❌ Invalid alternative index. Available: 1-${entry.alternatives.length}`);
    process.exit(1);
  }
  
  const alt = entry.alternatives[altIndex - 1];
  
  // Move current topic to alternatives if not already there
  const currentAsAlt = {
    topic: entry.topic,
    focus: entry.focus,
    keywords: entry.keywords
  };
  
  // Check if current topic is already in alternatives
  const currentInAlts = entry.alternatives.some(a => a.topic === entry.topic);
  if (!currentInAlts) {
    entry.alternatives.push(currentAsAlt);
  }
  
  // Switch to selected alternative
  entry.topic = alt.topic;
  entry.focus = alt.focus;
  entry.keywords = alt.keywords;
  
  // Remove selected alternative from list
  entry.alternatives.splice(altIndex - 1, 1);
  
  writeSchedule(schedule);
  console.log(`✅ Switched to alternative topic for ${date}: ${entry.topic}`);
}

// Regenerate proposals
function regenerateProposals(days, horizon) {
  console.log('🔄 Regenerating proposals...');
  
  const horizonArg = horizon ? `--horizon=${horizon}` : '';
  const daysArg = days ? `--days=${days}` : '';
  
  try {
    execSync(`node ${path.join(__dirname, 'generate-blog-proposals.js')} ${horizonArg}`, {
      stdio: 'inherit',
      cwd: path.join(__dirname, '..')
    });
  } catch (error) {
    console.error(`❌ Error regenerating proposals: ${error.message}`);
    process.exit(1);
  }
}

// Show status
function showStatus() {
  const schedule = readSchedule();
  const today = new Date();
  
  const upcoming = schedule.schedule.filter(s => new Date(s.date) >= today);
  const proposed = upcoming.filter(s => s.status === 'proposed').length;
  const approved = upcoming.filter(s => s.status === 'approved').length;
  const generated = upcoming.filter(s => s.status === 'generated').length;
  
  console.log('\n📊 Blog Schedule Status:\n');
  console.log(`   Total upcoming entries: ${upcoming.length}`);
  console.log(`   Proposed: ${proposed}`);
  console.log(`   Approved: ${approved}`);
  console.log(`   Generated: ${generated}`);
  console.log(`   Planning horizon: ${schedule.settings.planningHorizonDays} days`);
  console.log(`   Auto-approve: ${schedule.settings.requireApproval ? 'No' : 'Yes'}`);
  console.log(`   Last updated: ${schedule.lastUpdated}\n`);
}

// Configure settings
function configureSettings(options) {
  const schedule = readSchedule();
  
  if (options.horizon !== undefined) {
    schedule.settings.planningHorizonDays = parseInt(options.horizon);
    console.log(`✅ Set planning horizon to ${options.horizon} days`);
  }
  
  if (options.autoApprove !== undefined) {
    schedule.settings.requireApproval = !(options.autoApprove === 'true' || options.autoApprove === true);
    console.log(`✅ Set auto-approve to ${!schedule.settings.requireApproval}`);
  }
  
  writeSchedule(schedule);
}

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    showHelp();
    process.exit(0);
  }
  
  const command = args[0];
  const options = {};
  const positionalArgs = [];
  
  // Parse options and positional args
  for (let i = 1; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
      const [key, value] = arg.substring(2).split('=');
      options[key] = value !== undefined ? value : true;
    } else {
      positionalArgs.push(arg);
    }
  }
  
  return { command, options, args: positionalArgs };
}

// Show help
function showHelp() {
  console.log(`
📝 Blog Schedule Management CLI

Usage: node scripts/manage-blog-schedule.js <command> [options]

Commands:
  view [--days=N]              View upcoming schedule (default: 14 days)
  approve <date>                Approve a proposed topic
  edit <date> [options]         Edit a topic
                                Options: --topic, --focus, --keywords, --notes
  suggest <date> [options]      Suggest a new topic for a date
                                Required: --topic
                                Optional: --focus, --keywords, --notes
  add-research <date> --file    Add research notes file to a topic
  switch <date> --alternative=N Switch to an alternative topic (1-based index)
  regenerate [--days=N] [--horizon=N]  Regenerate proposals
  status                        Show schedule status
  config [options]              Configure settings
                                Options: --horizon=N, --auto-approve=true|false

Examples:
  node scripts/manage-blog-schedule.js view --days=7
  node scripts/manage-blog-schedule.js approve 2025-11-10
  node scripts/manage-blog-schedule.js suggest 2025-11-10 --topic "AWS Cost Management" --focus "Cost optimization strategies"
  node scripts/manage-blog-schedule.js add-research 2025-11-10 --file "docs/blog-research/cost-management.md"
  node scripts/manage-blog-schedule.js switch 2025-11-11 --alternative=1
  node scripts/manage-blog-schedule.js config --horizon=21 --auto-approve=true
`);
}

// Main
function main() {
  const { command, options, args } = parseArgs();
  
  switch (command) {
    case 'view':
      const days = options.days ? parseInt(options.days) : 14;
      viewSchedule(days);
      break;
      
    case 'approve':
      if (!args[1]) {
        console.error('❌ Date required');
        showHelp();
        process.exit(1);
      }
      approveTopic(args[1]);
      break;
      
    case 'edit':
      if (!args[1]) {
        console.error('❌ Date required');
        showHelp();
        process.exit(1);
      }
      editTopic(args[1], options);
      break;
      
    case 'suggest':
      if (!args[1] || !options.topic) {
        console.error('❌ Date and --topic required');
        showHelp();
        process.exit(1);
      }
      suggestTopic(args[1], options);
      break;
      
    case 'add-research':
      if (!args[1] || !options.file) {
        console.error('❌ Date and --file required');
        showHelp();
        process.exit(1);
      }
      addResearch(args[1], options.file);
      break;
      
    case 'switch':
      if (!args[1] || !options.alternative) {
        console.error('❌ Date and --alternative required');
        showHelp();
        process.exit(1);
      }
      switchAlternative(args[1], parseInt(options.alternative));
      break;
      
    case 'regenerate':
      regenerateProposals(options.days, options.horizon);
      break;
      
    case 'status':
      showStatus();
      break;
      
    case 'config':
      configureSettings(options);
      break;
      
    default:
      console.error(`❌ Unknown command: ${command}`);
      showHelp();
      process.exit(1);
  }
}

main();

