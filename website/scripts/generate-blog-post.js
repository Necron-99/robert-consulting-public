#!/usr/bin/env node

/**
 * Blog Post Generator
 * 
 * Usage: node generate-blog-post.js
 * 
 * This script helps create new blog posts by:
 * 1. Prompting for post details
 * 2. Generating the HTML file from template
 * 3. Updating the blog.js posts array
 * 4. Updating sitemap.xml
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(prompt) {
    return new Promise((resolve) => {
        rl.question(prompt, resolve);
    });
}

function generateSlug(title) {
    return title
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim('-');
}

function formatDate(date) {
    return date.toISOString().split('T')[0];
}

function formatDateDisplay(date) {
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

function estimateReadTime(content) {
    const wordsPerMinute = 200;
    const wordCount = content.split(/\s+/).length;
    const minutes = Math.ceil(wordCount / wordsPerMinute);
    return `${minutes} min read`;
}

async function generateBlogPost() {
    console.log('📝 Blog Post Generator\n');
    
    try {
        // Collect post information
        const title = await question('Post title: ');
        const description = await question('Meta description: ');
        const category = await question('Category (aws/terraform/cicd/security/devops): ');
        const icon = await question('Icon emoji: ');
        const tagsInput = await question('Tags (comma-separated): ');
        const content = await question('Post content (HTML): ');
        
        const tags = tagsInput.split(',').map(tag => tag.trim());
        const slug = generateSlug(title);
        const date = new Date();
        const formattedDate = formatDate(date);
        const formattedDateDisplay = formatDateDisplay(date);
        const readTime = estimateReadTime(content);
        const keywords = tags.join(', ');
        
        // Generate HTML file
        const templatePath = path.join(__dirname, '..', 'blog-post-template.html');
        const template = fs.readFileSync(templatePath, 'utf8');
        
        const html = template
            .replace(/\{\{TITLE\}\}/g, title)
            .replace(/\{\{DESCRIPTION\}\}/g, description)
            .replace(/\{\{KEYWORDS\}\}/g, keywords)
            .replace(/\{\{SLUG\}\}/g, slug)
            .replace(/\{\{DATE\}\}/g, formattedDate)
            .replace(/\{\{FORMATTED_DATE\}\}/g, formattedDateDisplay)
            .replace(/\{\{READ_TIME\}\}/g, readTime)
            .replace(/\{\{CATEGORY_UPPER\}\}/g, category.toUpperCase())
            .replace(/\{\{ICON\}\}/g, icon)
            .replace(/\{\{CONTENT\}\}/g, content)
            .replace(/\{\{TAGS_HTML\}\}/g, tags.map(tag => `<span class="blog-tag">${tag}</span>`).join(''));
        
        // Write HTML file
        const outputPath = path.join(__dirname, '..', 'blog-posts', `${slug}.html`);
        fs.writeFileSync(outputPath, html);
        console.log(`✅ Created: ${outputPath}`);
        
        // Update blog.js
        const blogJsPath = path.join(__dirname, '..', 'js', 'blog.js');
        let blogJs = fs.readFileSync(blogJsPath, 'utf8');
        
        const newPost = {
            id: Date.now(),
            title: title,
            excerpt: description.substring(0, 150) + '...',
            content: `blog-posts/${slug}.html`,
            date: formattedDate,
            category: category,
            tags: tags,
            icon: icon,
            readTime: readTime
        };
        
        // Find the posts array and add new post
        const postsArrayMatch = blogJs.match(/this\.posts = \[([\s\S]*?)\];/);
        if (postsArrayMatch) {
            const existingPosts = postsArrayMatch[1].trim();
            const newPostsArray = `this.posts = [\n            ${JSON.stringify(newPost, null, 12)},\n            ${existingPosts}\n        ];`;
            blogJs = blogJs.replace(/this\.posts = \[[\s\S]*?\];/, newPostsArray);
            fs.writeFileSync(blogJsPath, blogJs);
            console.log('✅ Updated blog.js');
        }
        
        // Update sitemap.xml
        const sitemapPath = path.join(__dirname, '..', 'sitemap.xml');
        let sitemap = fs.readFileSync(sitemapPath, 'utf8');
        
        const newSitemapEntry = `  <url>
    <loc>https://robertconsulting.net/blog-posts/${slug}.html</loc>
    <lastmod>${formattedDate}</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
`;
        
        // Insert before the closing </urlset> tag
        sitemap = sitemap.replace('</urlset>', `${newSitemapEntry}</urlset>`);
        fs.writeFileSync(sitemapPath, sitemap);
        console.log('✅ Updated sitemap.xml');
        
        console.log('\n🎉 Blog post generated successfully!');
        console.log(`📄 File: blog-posts/${slug}.html`);
        console.log(`🔗 URL: https://robertconsulting.net/blog-posts/${slug}.html`);
        
    } catch (error) {
        console.error('❌ Error generating blog post:', error.message);
    } finally {
        rl.close();
    }
}

// Run the generator
generateBlogPost();
