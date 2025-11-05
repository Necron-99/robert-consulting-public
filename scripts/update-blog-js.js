#!/usr/bin/env node
// Script to update blog.js with a new blog post entry

import fs from 'fs';

const day = process.env.DAY;
const dateOnly = process.env.DATE_ONLY;
const title = process.env.TITLE;
const excerpt = process.env.EXCERPT;
const category = process.env.CATEGORY;
const tagsStr = process.env.TAGS_STR;
const icon = process.env.ICON;
const readTime = process.env.READ_TIME;
const dayCap = process.env.DAY_CAP;
const blogJs = process.env.BLOG_JS;

if (!blogJs) {
  console.error('❌ Error: BLOG_JS environment variable not set');
  process.exit(1);
}

const blogJsContent = fs.readFileSync(blogJs, 'utf8');

// Find max ID
const idMatches = blogJsContent.match(/id: (\d+)/g) || [];
const maxId = idMatches.length > 0 ? Math.max(...idMatches.map(m => parseInt(m.match(/\d+/)[0]))) : 0;
const nextId = maxId + 1;

// Find the insertion point (before the closing ];)
const closingBracketIndex = blogJsContent.lastIndexOf('    ];');
if (closingBracketIndex === -1) {
  console.error('❌ Could not find closing bracket ];');
  process.exit(1);
}

// Get content before closing bracket
const beforeClosing = blogJsContent.substring(0, closingBracketIndex);

// Find the last entry's closing brace (6 spaces + })
const lastBraceIndex = beforeClosing.lastIndexOf('      }');
if (lastBraceIndex === -1) {
  console.error('❌ Could not find last entry closing brace');
  process.exit(1);
}

// Check if last entry already has a comma
const textBeforeLastBrace = beforeClosing.substring(0, lastBraceIndex).trimEnd();
const needsComma = !textBeforeLastBrace.endsWith(',');

// Create new entry
const newEntry = `      {
        id: ${nextId},
        title: '${title.replace(/'/g, "\\'")}',
        excerpt: '${excerpt.replace(/'/g, "\\'")}',
        content: 'blog-posts/${day}-${dateOnly}.html',
        date: '${dateOnly}', // ${dayCap}
        category: '${category}',
        tags: ${tagsStr},
        icon: '${icon}',
        readTime: '${readTime}'
      }`;

// Build the result: insert new entry before the closing ];
const beforeInsert = beforeClosing.substring(0, lastBraceIndex + 7); // Include '      }'
const afterInsert = blogJsContent.substring(closingBracketIndex);
const result = beforeInsert + (needsComma ? ',' : '') + ',\n' + newEntry + '\n' + afterInsert;

fs.writeFileSync(blogJs, result, 'utf8');

console.log('✅ Added blog entry to blog.js:');
console.log('   ID:', nextId);
console.log('   Title:', title);
console.log('   Date:', dateOnly);
console.log('   Category:', category);

