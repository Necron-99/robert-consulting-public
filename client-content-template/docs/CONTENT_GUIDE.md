# Content Management Guide

## Content Structure

### Website Files
```
content/website/
├── index.html          # Main page
├── about.html          # About page
├── contact.html        # Contact page
├── css/
│   ├── style.css       # Main stylesheet
│   └── responsive.css   # Responsive styles
├── js/
│   ├── main.js         # Main JavaScript
│   └── contact.js      # Contact form handling
└── assets/
    ├── images/         # Images and graphics
    ├── icons/          # Favicons and icons
    └── fonts/          # Custom fonts
```

### File Organization
- **HTML files**: Root level for easy access
- **CSS files**: Organized in `css/` directory
- **JavaScript files**: Organized in `js/` directory
- **Assets**: Images, icons, fonts in `assets/` directory

## Content Guidelines

### HTML Best Practices
- **Semantic markup**: Use proper HTML5 semantic elements
- **Accessibility**: Include alt text, proper headings, ARIA labels
- **SEO**: Meta tags, structured data, proper heading hierarchy
- **Performance**: Optimize for loading speed

### CSS Best Practices
- **Mobile-first**: Responsive design approach
- **Performance**: Minimize CSS, use efficient selectors
- **Maintainability**: Clear naming conventions, organized structure
- **Cross-browser**: Test across different browsers

### JavaScript Best Practices
- **Performance**: Minimize JavaScript, lazy loading
- **Accessibility**: Keyboard navigation, screen reader support
- **Error handling**: Graceful degradation
- **Security**: Sanitize inputs, prevent XSS

### Image Guidelines
- **Optimization**: Compress images before committing
- **Formats**: Use appropriate formats (WebP, JPEG, PNG)
- **Sizing**: Responsive images with proper srcset
- **Alt text**: Descriptive alt text for accessibility

## Deployment Process

### Automatic Deployment
1. **Make changes** to content files
2. **Commit and push** to main branch
3. **GitHub Actions** automatically deploys
4. **CloudFront cache** is invalidated
5. **Changes go live** within minutes

### Manual Deployment
```bash
cd content
./deploy.sh
```

### Deployment Validation
- **HTML validation**: Automated HTML validation
- **CSS validation**: Automated CSS linting
- **JavaScript validation**: Automated JS linting
- **Link checking**: Automated link validation

## Content Updates

### Adding New Pages
1. **Create HTML file** in `content/website/`
2. **Add navigation links** in existing pages
3. **Update CSS** if needed for styling
4. **Commit and push** changes

### Updating Existing Content
1. **Edit existing files** in `content/website/`
2. **Test changes** locally if possible
3. **Commit and push** changes
4. **Monitor deployment** in GitHub Actions

### Adding Assets
1. **Add files** to appropriate `assets/` subdirectory
2. **Update HTML** to reference new assets
3. **Commit and push** changes
4. **Verify deployment** on live site

## Performance Optimization

### Image Optimization
- **Compress images**: Use tools like ImageOptim, TinyPNG
- **Choose formats**: WebP for photos, PNG for graphics
- **Responsive images**: Use srcset for different screen sizes
- **Lazy loading**: Implement lazy loading for images

### CSS Optimization
- **Minify CSS**: Remove unnecessary whitespace
- **Combine files**: Reduce HTTP requests
- **Critical CSS**: Inline critical CSS
- **Remove unused**: Remove unused CSS rules

### JavaScript Optimization
- **Minify JS**: Remove unnecessary whitespace
- **Combine files**: Reduce HTTP requests
- **Async loading**: Load non-critical JS asynchronously
- **Remove unused**: Remove unused JavaScript

## Security Considerations

### Content Security
- **Input validation**: Validate all user inputs
- **XSS prevention**: Sanitize user-generated content
- **HTTPS**: Ensure all resources use HTTPS
- **Security headers**: Managed by infrastructure

### Access Control
- **Repository access**: Private repositories only
- **Deployment credentials**: Minimal AWS permissions
- **Content validation**: Automated security scanning

## Monitoring and Analytics

### Performance Monitoring
- **Page load times**: CloudFront performance metrics
- **Error rates**: 4xx/5xx error tracking
- **Cache hit rates**: CloudFront cache efficiency
- **User experience**: Real user monitoring

### Content Analytics
- **Page views**: Track popular content
- **User behavior**: Understand user journeys
- **Conversion tracking**: Track business goals
- **A/B testing**: Test content variations

## Troubleshooting

### Common Issues

#### Deployment Failures
- **Check AWS credentials**: Verify GitHub secrets
- **Check SSM parameters**: Ensure infrastructure is deployed
- **Check S3 permissions**: Verify bucket access
- **Check CloudFront**: Verify distribution exists

#### Content Not Updating
- **Check S3 sync**: Verify files uploaded to S3
- **Check CloudFront**: Verify cache invalidation
- **Check DNS**: Verify domain resolution
- **Check browser cache**: Clear browser cache

#### Performance Issues
- **Check image sizes**: Optimize large images
- **Check CSS/JS**: Minimize and combine files
- **Check CloudFront**: Verify CDN configuration
- **Check server response**: Monitor response times

### Recovery Procedures

#### Content Rollback
```bash
# Rollback to previous version
git revert HEAD
git push origin main
```

#### Manual Cache Clear
```bash
# Manual CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*"
```

#### Content Restore
```bash
# Restore from S3 versioning
aws s3 cp s3://BUCKET_NAME/ --recursive --restore-request Days=1
```

## Best Practices

### Content Management
- **Version control**: All content in git
- **Automated deployment**: CI/CD for all changes
- **Content validation**: Automated quality checks
- **Backup procedures**: Git-based backups

### Performance
- **Image optimization**: Compress images before commit
- **CSS/JS minification**: Minify assets for production
- **Cache optimization**: Proper cache headers
- **CDN usage**: Leverage CloudFront caching

### Security
- **Content scanning**: Automated security checks
- **Access control**: Private repositories
- **Audit logging**: Track all deployments
- **Vulnerability scanning**: Regular security scans

### Collaboration
- **Clear documentation**: Document content guidelines
- **Review process**: Use pull requests for changes
- **Testing**: Test changes before deployment
- **Communication**: Keep team informed of changes
