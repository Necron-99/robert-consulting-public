#!/bin/bash

# Enhanced Blog Post Generator - SEO-Friendly with Weekday Subjects
# Usage: ./generate-blog-post.sh [day] "Post Title" "Description" "keywords,seo,terms" "slug-name"
# Or: ./generate-blog-post.sh --suggest [day] (to get topic suggestions)

# Function to get weekday subject
get_weekday_subject() {
    case "$1" in
        "monday") echo "AWS & Cloud Infrastructure" ;;
        "tuesday") echo "DevOps & Automation" ;;
        "wednesday") echo "Security & DevSecOps" ;;
        "thursday") echo "Infrastructure as Code (IaC)" ;;
        "friday") echo "Container Orchestration & Advanced Topics" ;;
        *) echo "General DevOps Topics" ;;
    esac
}

# Function to get weekday keywords
get_weekday_keywords() {
    case "$1" in
        "monday") echo "aws,cloud,infrastructure,optimization,well-architected,lambda,s3,cloudfront" ;;
        "tuesday") echo "devops,ci/cd,automation,github-actions,pipeline,deployment" ;;
        "wednesday") echo "security,devsecops,scanning,sast,dast,compliance" ;;
        "thursday") echo "terraform,terragrunt,iac,infrastructure,modules,state-management" ;;
        "friday") echo "kubernetes,containers,argocd,gitops,orchestration" ;;
        *) echo "devops,automation,infrastructure" ;;
    esac
}

# Function to get weekday topics
get_weekday_topics() {
    case "$1" in
        "monday") echo "AWS cost optimization|AWS service optimization|Cloud architecture patterns|AWS Well-Architected Framework|Cloud security best practices" ;;
        "tuesday") echo "CI/CD pipeline setup|DevOps automation|GitHub Actions workflows|Pipeline optimization|Deployment automation" ;;
        "wednesday") echo "DevSecOps implementation|Security scanning|Compliance frameworks|Security automation|Threat modeling" ;;
        "thursday") echo "Terraform module design|Terragrunt best practices|Infrastructure patterns|State management|Module composition" ;;
        "friday") echo "Kubernetes deployment|Container orchestration|GitOps workflows|Advanced DevOps|Emerging technologies" ;;
        *) echo "DevOps best practices|Infrastructure automation|CI/CD optimization" ;;
    esac
}

# Function to show topic suggestions
show_suggestions() {
    local day=$1
    local day_lower=$(echo "$day" | tr '[:upper:]' '[:lower:]')
    local subject=$(get_weekday_subject "$day_lower")
    local keywords=$(get_weekday_keywords "$day_lower")
    local topics=$(get_weekday_topics "$day_lower")
    
    echo "📅 $day - $subject"
    echo "🏷️  Suggested Keywords: $keywords"
    echo ""
    echo "💡 Topic Suggestions:"
    IFS='|' read -ra TOPICS_ARRAY <<< "$topics"
    for i in "${!TOPICS_ARRAY[@]}"; do
        echo "   $((i+1)). ${TOPICS_ARRAY[$i]}"
    done
    echo ""
    echo "📝 Example Usage:"
    echo "   ./generate-blog-post.sh $day \"Your Title Here\" \"Description\" \"$keywords\" \"slug-name\""
}

# Function to generate blog post
generate_post() {
    local day=$1
    local title=$2
    local description=$3
    local keywords=$4
    local slug=$5
    local date=$(date +"%B %d, %Y")
    local filename="website/blog-posts/${slug}.html"
    local day_lower=$(echo "$day" | tr '[:upper:]' '[:lower:]')
    local subject=$(get_weekday_subject "$day_lower")
    local day_keywords=$(get_weekday_keywords "$day_lower")
    
    # Add day-specific keywords if not provided
    if [[ -n "$day_keywords" ]]; then
        keywords="${day_keywords},${keywords}"
    fi
    
    echo "📅 Generating blog post for: $day - $subject"
    echo "📝 Title: $title"
    echo "🔗 Slug: $slug"
    echo "📄 Output: $filename"
    echo ""
    
    # Create the blog post from template
    cp website/blog-post-template.html "$filename"
    
    # Replace placeholders
    sed -i '' "s/{{TITLE}}/$title/g" "$filename"
    sed -i '' "s/{{DESCRIPTION}}/$description/g" "$filename"
    sed -i '' "s/{{KEYWORDS}}/$keywords/g" "$filename"
    sed -i '' "s/{{SLUG}}/$slug/g" "$filename"
    sed -i '' "s/{{DATE}}/$date/g" "$filename"
    
    # Add content placeholder with day-specific guidance
    cat >> "$filename" << CONTENT_EOF

    <!-- Blog Post Content -->
    <article class="blog-post">
        <header class="post-header">
            <h1 class="post-title">$title</h1>
            <div class="post-meta">
                <span class="post-date">$date</span>
                <span class="post-author">Robert Bailey</span>
                <span class="post-category">$subject</span>
            </div>
        </header>
        
        <div class="post-content">
            <!-- $day Focus: $subject -->
            
            <h2>Introduction</h2>
            <p>Start with an engaging introduction that hooks your readers and explains the problem you're solving.</p>
            
            <h2>The Challenge</h2>
            <p>Describe the specific challenge or problem that this post addresses.</p>
            
            <h2>Solution Overview</h2>
            <p>Provide a high-level overview of your approach or solution.</p>
            
            <h2>Implementation</h2>
            <p>Add detailed implementation steps, code examples, or configuration details.</p>
            
            <h2>Results & Metrics</h2>
            <p>Include quantifiable results, performance improvements, or cost savings.</p>
            
            <h2>Best Practices</h2>
            <p>Share lessons learned and best practices for others to follow.</p>
            
            <h2>Conclusion</h2>
            <p>Wrap up with key takeaways and next steps for readers.</p>
        </div>
        
        <footer class="post-footer">
            <div class="post-tags">
                <span class="tag-label">Tags:</span>
                <span class="tag">#$keywords</span>
            </div>
            <div class="post-category">
                <span class="category-label">Category:</span>
                <span class="category">$subject</span>
            </div>
        </footer>
    </article>
</body>
</html>
CONTENT_EOF
    
    echo "✅ Blog post generated: $filename"
    echo "📝 Edit the content section to add your blog post content"
    echo "🚀 Deploy with: aws s3 cp $filename s3://robert-consulting-website/blog-posts/"
    echo ""
    echo "💡 Remember: This is a $day post focusing on $subject"
    
    # Optional: Open in editor
    if command -v code &> /dev/null; then
        echo "📝 Opening in VS Code..."
        code "$filename"
    elif command -v nano &> /dev/null; then
        echo "📝 Opening in nano..."
        nano "$filename"
    fi
}

# Main script logic
if [ "$1" = "--suggest" ] || [ "$1" = "-s" ]; then
    if [ $# -ne 2 ]; then
        echo "Usage: $0 --suggest [monday|tuesday|wednesday|thursday|friday]"
        exit 1
    fi
    show_suggestions "$2"
elif [ $# -eq 5 ]; then
    generate_post "$1" "$2" "$3" "$4" "$5"
elif [ $# -eq 4 ]; then
    # Auto-detect day if not provided
    day=$(date +"%A" | tr '[:upper:]' '[:lower:]')
    echo "📅 Auto-detected day: $day"
    generate_post "$day" "$1" "$2" "$3" "$4"
else
    echo "Enhanced Blog Post Generator"
    echo ""
    echo "Usage:"
    echo "  $0 [day] \"Post Title\" \"Description\" \"keywords,seo,terms\" \"slug-name\""
    echo "  $0 --suggest [monday|tuesday|wednesday|thursday|friday]"
    echo ""
    echo "Examples:"
    echo "  $0 monday \"AWS Cost Optimization\" \"Learn cost reduction strategies\" \"aws,cost,optimization\" \"aws-cost-optimization\""
    echo "  $0 --suggest monday"
    echo ""
    echo "Weekday Subjects:"
    echo "  monday: $(get_weekday_subject 'monday')"
    echo "  tuesday: $(get_weekday_subject 'tuesday')"
    echo "  wednesday: $(get_weekday_subject 'wednesday')"
    echo "  thursday: $(get_weekday_subject 'thursday')"
    echo "  friday: $(get_weekday_subject 'friday')"
fi
