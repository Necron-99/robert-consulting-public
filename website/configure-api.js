#!/usr/bin/env node

/**
 * API Configuration Script
 * Safely replaces API placeholders with actual values
 */

const fs = require('fs');
const path = require('path');

// Get command line arguments
const apiEndpoint = process.argv[2];
const apiKey = process.argv[3];

if (!apiEndpoint || !apiKey) {
  console.error('Usage: node configure-api.js <api-endpoint> <api-key>');
  process.exit(1);
}

// Read the API config file
const configPath = path.join(__dirname, 'js', 'api-config.js');

if (!fs.existsSync(configPath)) {
  console.error('API config file not found:', configPath);
  process.exit(1);
}

// Read file content
let content = fs.readFileSync(configPath, 'utf8');

// Replace placeholders
content = content.replace(/PLACEHOLDER_API_ENDPOINT/g, apiEndpoint);
content = content.replace(/PLACEHOLDER_API_KEY/g, apiKey);

// Write back to file
fs.writeFileSync(configPath, content);

console.log('API configuration updated successfully');
console.log('Endpoint:', apiEndpoint);
console.log('Key:', apiKey.substring(0, 8) + '...');
