# Enhanced Blog Planning System - Implementation Plan

## Overview

Transform the current day-of-generation blog system into a proactive planning system that generates a week's worth of proposed topics, allows review/editing, and provides a clear planning horizon.

---

## Current System Analysis

### Current Flow
1. **Daily Generation**: Workflow runs at 9 AM each weekday
2. **Topic Selection**: Hardcoded topics based on day of week
3. **Date Overrides**: Manual date-specific overrides in workflow YAML
4. **No Planning**: No visibility into upcoming topics until generation day

### Limitations
- No ability to plan ahead
- Manual overrides require code changes
- No way to review or suggest topics
- No topic history or tracking
- Limited flexibility for special topics

---

## Proposed System Architecture

### Core Components

#### 1. **Topic Planning File** (`blog-schedule.json`)
Central JSON file storing planned topics for upcoming weeks.

**Structure:**
```json
{
  "version": "1.0",
  "lastUpdated": "2025-11-07T10:00:00Z",
  "schedule": [
    {
      "date": "2025-11-10",
      "day": "monday",
      "status": "approved",  // proposed, approved, generated, skipped
      "topic": "AWS Cost Management",
      "focus": "Practical strategies to keep AWS costs in check and avoid unexpected charges",
      "keywords": "AWS cost optimization, cost management, AWS billing, cost control",
      "category": "aws",
      "icon": "💰",
      "tags": ["AWS Cost Optimization", "Cost Management", "AWS Billing"],
      "readTime": "12 min read",
      "notes": "User requested - fresh from recent cost optimization work",
      "suggestedBy": "user",  // system, user, ai
      "suggestedAt": "2025-11-07T10:00:00Z",
      "approvedBy": "user",
      "approvedAt": "2025-11-07T10:05:00Z"
    },
    {
      "date": "2025-11-11",
      "day": "tuesday",
      "status": "approved",  // Auto-approved by default
      "topic": "CI/CD Pipeline Optimization",
      "focus": "Strategies for optimizing CI/CD pipelines for speed and cost efficiency",
      "keywords": "CI/CD, pipeline optimization, DevOps automation, build performance",
      "category": "devops",
      "icon": "⚙️",
      "tags": ["CI/CD", "Pipeline Optimization", "DevOps"],
      "readTime": "10 min read",
      "notes": "",
      "researchNotes": "",  // Path to research notes file (optional)
      "suggestedBy": "ai",
      "suggestedAt": "2025-11-07T10:00:00Z",
      "approvedBy": "system",  // Auto-approved
      "approvedAt": "2025-11-07T10:00:00Z",
      "alternatives": [  // Optional alternative topics
        {
          "topic": "GitHub Actions Best Practices",
          "focus": "Advanced GitHub Actions workflows and optimization techniques",
          "keywords": "GitHub Actions, CI/CD, automation, workflows"
        },
        {
          "topic": "DevOps Automation Patterns",
          "focus": "Common automation patterns for infrastructure and deployment",
          "keywords": "DevOps, automation, patterns, infrastructure"
        }
      ]
    }
  ],
  "defaultTopics": {
    "monday": {
      "topic": "AWS & Cloud Infrastructure",
      "focus": "Latest developments, best practices, and insights in AWS and cloud infrastructure",
      "keywords": "AWS, cloud infrastructure, cloud services, AWS best practices, cloud architecture"
    },
    "tuesday": {
      "topic": "DevOps & Automation",
      "focus": "DevOps methodologies, automation strategies, CI/CD pipelines, and operational excellence",
      "keywords": "DevOps, automation, CI/CD, continuous integration, continuous deployment, operational excellence"
    },
    "wednesday": {
      "topic": "Security & DevSecOps",
      "focus": "Security best practices, DevSecOps integration, threat detection, and vulnerability management",
      "keywords": "security, DevSecOps, threat detection, vulnerability management, security automation, cybersecurity"
    },
    "thursday": {
      "topic": "Infrastructure as Code (IaC)",
      "focus": "Terraform, OpenTofu, CloudFormation, and infrastructure automation strategies",
      "keywords": "Infrastructure as Code, IaC, Terraform, OpenTofu, CloudFormation, infrastructure automation"
    },
    "friday": {
      "topic": "Container Orchestration & Advanced Topics",
      "focus": "Kubernetes, Docker, container orchestration, and advanced cloud-native technologies",
      "keywords": "Kubernetes, Docker, container orchestration, cloud-native, microservices, advanced topics"
    }
  },
  "settings": {
    "planningHorizonDays": 14,  // Generate topics for next 14 days (configurable, default: 14)
    "autoGenerateProposals": true,
    "requireApproval": false,  // If false, auto-approve proposed topics (default: false)
    "regenerateThreshold": 7,   // Regenerate proposals when less than 7 days remain
    "proposalMethod": "template" // "template", "github-copilot", "openai", "anthropic"
  }
}
```

#### 2. **Topic Proposal Generator** (`scripts/generate-blog-proposals.js`)
Node.js script that generates AI-powered topic proposals for upcoming week.

**Functionality:**
- Analyzes recent blog posts to avoid repetition
- Considers weekly schedule (Monday = AWS, Tuesday = DevOps, etc.)
- Generates specific topics within each day's theme
- Includes focus, keywords, and metadata
- Writes proposals to `blog-schedule.json`

**Input:**
- Number of days to plan ahead (default: 14)
- Reference to existing blog posts
- Weekly schedule themes

**Output:**
- Updated `blog-schedule.json` with proposed topics

#### 3. **Topic Management Script** (`scripts/manage-blog-schedule.js`)
CLI tool for reviewing, approving, editing, and managing blog topics.

**Commands:**
```bash
# View upcoming schedule
node scripts/manage-blog-schedule.js view [--days 7]

# Approve a topic
node scripts/manage-blog-schedule.js approve <date>

# Edit a topic
node scripts/manage-blog-schedule.js edit <date> --topic "New Topic" --focus "New focus"

# Suggest a topic for a specific date
node scripts/manage-blog-schedule.js suggest <date> --topic "Topic" --focus "Focus"

# Add research notes to a topic
node scripts/manage-blog-schedule.js add-research <date> --file "docs/blog-research/topic.md"

# Switch to alternative topic
node scripts/manage-blog-schedule.js switch <date> --alternative 1

# Regenerate proposals
node scripts/manage-blog-schedule.js regenerate [--days 14] [--horizon 14]

# Show status
node scripts/manage-blog-schedule.js status

# Configure settings
node scripts/manage-blog-schedule.js config --horizon 21 --auto-approve true
```

#### 4. **Weekly Planning Workflow** (`.github/workflows/blog-planning.yml`)
GitHub Actions workflow that runs weekly to generate topic proposals.

**Schedule:**
- Runs every Sunday at 6 PM
- Generates proposals for next 14 days
- Creates a PR with proposed topics
- Allows review and approval before merging

**Workflow Steps:**
1. Checkout repository
2. Generate topic proposals
3. Create/update `blog-schedule.json`
4. Create PR with proposed topics
5. Post summary comment in PR

#### 5. **Enhanced Blog Generation Workflow**
Updated `automated-blog-generation.yml` to read from `blog-schedule.json`.

**Changes:**
- Check `blog-schedule.json` for scheduled topic for today's date
- If found and status is "approved", use that topic
- If not found or status is "proposed", fall back to default topic for day
- After generation, update status to "generated"
- Log topic source (scheduled vs. default)

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Create data structure and basic management tools

**Tasks:**
1. ✅ Create `blog-schedule.json` structure
2. ✅ Create `scripts/manage-blog-schedule.js` with basic CRUD operations
3. ✅ Add validation for JSON schema
4. ✅ Create documentation for topic management

**Deliverables:**
- `blog-schedule.json` file with initial structure
- Basic CLI tool for viewing/editing topics
- Documentation

### Phase 2: Proposal Generation (Week 1-2)
**Goal**: Automate topic proposal generation

**Tasks:**
1. ✅ Create `scripts/generate-blog-proposals.js`
2. ✅ Start with template-based generation (zero cost)
3. ✅ Generate 1 primary + 2-3 alternative proposals per day
4. ✅ Add logic to avoid topic repetition
5. ✅ Generate proposals based on weekly themes
6. ✅ Integrate research notes lookup
7. ✅ Test proposal quality and relevance
8. ✅ Optional: Add AI/LLM integration (GitHub Copilot, OpenAI, etc.)

**Deliverables:**
- Proposal generation script (template-based initially)
- Test proposals for next 14 days
- Quality metrics/validation
- Research notes integration

### Phase 3: Workflow Integration (Week 2)
**Goal**: Integrate planning system with existing blog generation

**Tasks:**
1. ✅ Update `automated-blog-generation.yml` to read from `blog-schedule.json`
2. ✅ Add fallback logic for missing/unscheduled topics
3. ✅ Update status tracking after generation
4. ✅ Test end-to-end flow

**Deliverables:**
- Updated blog generation workflow
- Status tracking
- Error handling and fallbacks

### Phase 4: Weekly Planning Workflow (Week 2-3)
**Goal**: Automate weekly proposal generation

**Tasks:**
1. ✅ Create `.github/workflows/blog-planning.yml`
2. ✅ Set up PR creation for review
3. ✅ Add PR comment with schedule summary
4. ✅ Test weekly automation

**Deliverables:**
- Weekly planning workflow
- PR automation
- Review process

### Phase 5: Enhancement & Polish (Week 3-4)
**Goal**: Improve UX and add advanced features

**Tasks:**
1. ✅ Add topic history tracking
2. ✅ Add topic analytics (which topics perform well)
3. ✅ Improve proposal quality based on feedback
4. ✅ Add bulk operations (approve all, regenerate week, etc.)
5. ✅ Add topic templates for common topics
6. ✅ Create web UI (optional, future enhancement)

**Deliverables:**
- Enhanced CLI with analytics
- Topic templates
- Documentation updates

---

## File Structure

```
.
├── blog-schedule.json                    # Main planning file
├── scripts/
│   ├── generate-blog-proposals.js      # AI topic proposal generator
│   ├── manage-blog-schedule.js         # CLI management tool
│   └── validate-blog-schedule.js       # JSON schema validator
├── .github/
│   └── workflows/
│       ├── automated-blog-generation.yml  # Updated to use schedule
│       └── blog-planning.yml              # Weekly proposal generation
├── docs/
│   ├── plans/
│   │   └── enhanced-blog-planning-system.md  # This file
│   └── guides/
│       └── blog-topic-management.md         # User guide
└── schemas/
    └── blog-schedule.schema.json            # JSON schema for validation
```

---

## User Workflows

### Workflow 1: Weekly Planning (Automated)
1. **Sunday 6 PM**: Weekly planning workflow runs
2. **Proposal Generation**: AI generates topics for next 14 days
3. **PR Creation**: PR created with proposed topics
4. **Review**: User reviews and approves/edits topics
5. **Merge**: PR merged, topics become active

### Workflow 2: Manual Topic Scheduling
1. **User decides**: "I want to write about X on Monday"
2. **CLI Command**: `node scripts/manage-blog-schedule.js suggest 2025-11-10 --topic "AWS Cost Management" --focus "..." --keywords "..."`
3. **Add Research**: `node scripts/manage-blog-schedule.js add-research 2025-11-10 --file "docs/blog-research/monday-aws-cost-management.md"`
4. **Status Update**: Topic added with status "approved"
5. **Generation Day**: Blog generated with scheduled topic and research notes

### Workflow 3: Daily Blog Generation (Updated)
1. **9 AM Daily**: Blog generation workflow runs
2. **Check Schedule**: Look up today's date in `blog-schedule.json`
3. **Topic Selection**:
   - If scheduled topic exists and status is "approved" → use scheduled topic
   - Else → use default topic for day of week
4. **Load Research Notes**: If research notes path exists, include in generation context
5. **Generate**: Create blog post with selected topic and research notes
6. **Update Status**: Mark topic as "generated" in schedule

### Workflow 4: Topic Review & Editing
1. **View Schedule**: `node scripts/manage-blog-schedule.js view`
2. **Review Topics**: See all proposed/approved topics
3. **Edit Topic**: `node scripts/manage-blog-schedule.js edit 2025-11-11 --topic "New Topic"`
4. **Approve**: `node scripts/manage-blog-schedule.js approve 2025-11-11`
5. **Commit**: Changes committed to repository

---

## Technical Details

### Topic Proposal Generation Logic

**Inputs:**
- Weekly theme for each day (from `defaultTopics`)
- Recent blog post history (last 30 days)
- Research notes (from `docs/blog-research/`)
- User preferences/suggestions

**Process:**
1. For each day in planning horizon:
   - Get default theme for day of week
   - Check if specific topic already scheduled
   - If not, generate 1 primary topic proposal + 2-3 alternative options
   - Score proposals based on:
     - Relevance to theme
     - Uniqueness (not recently covered)
     - User interest (from research notes)
     - Current industry trends
   - Select best proposal as primary
   - Add primary to schedule with status "approved" (if auto-approve enabled)
   - Add alternatives to "alternatives" array
   - Check for linked research notes in `docs/blog-research/`

**Output:**
- Updated `blog-schedule.json` with primary proposals (auto-approved by default)
- Alternative topics stored for easy switching

### Status Flow

```
proposed → approved → generated
    ↓         ↓
  skipped   skipped
```

**Status Meanings:**
- `proposed`: AI-generated, awaiting review
- `approved`: User-approved, ready for generation
- `generated`: Blog post created
- `skipped`: Topic skipped (user decision or conflict)

### Validation Rules

1. **Date Validation**: Dates must be future dates, weekdays only
2. **Topic Uniqueness**: No duplicate topics within 30 days
3. **Required Fields**: topic, focus, keywords must be present
4. **Status Transitions**: Only valid transitions allowed
5. **Planning Horizon**: Must maintain at least 7 days of approved topics

---

## Benefits

### For User
- ✅ **Planning Visibility**: See upcoming topics at least a week ahead
- ✅ **Control**: Approve, edit, or suggest topics
- ✅ **Flexibility**: Schedule specific topics for specific dates
- ✅ **Quality**: AI-generated proposals reduce decision fatigue
- ✅ **History**: Track what topics have been covered

### For System
- ✅ **Consistency**: Maintains weekly schedule themes
- ✅ **Automation**: Reduces manual intervention
- ✅ **Scalability**: Easy to extend with more features
- ✅ **Reliability**: Fallback to defaults if schedule missing
- ✅ **Auditability**: Full history of topic decisions

---

## Future Enhancements (Post-MVP)

1. **Topic Analytics**
   - Track which topics get most engagement
   - Suggest topics based on performance data
   - Identify topic gaps or over-coverage

2. **Research Integration**
   - Auto-link research notes to topics
   - Suggest topics based on research files
   - Generate proposals from research summaries

3. **Collaboration Features**
   - Multiple users can suggest topics
   - Topic voting/ranking
   - Comments on topics

4. **Web UI**
   - Visual calendar view of schedule
   - Drag-and-drop topic reordering
   - Rich text editing for topics

5. **Advanced AI**
   - Learn from user edits to improve proposals
   - Seasonal topic suggestions
   - Industry event integration (AWS re:Invent, etc.)

---

## Migration Strategy

### Step 1: Add New System Alongside Old
- Create `blog-schedule.json` with empty schedule
- Keep existing workflow unchanged
- Test new system in parallel

### Step 2: Populate Initial Schedule
- Generate proposals for next 14 days
- Manually approve/edit as needed
- Keep existing date overrides temporarily

### Step 3: Update Generation Workflow
- Modify workflow to check schedule first
- Keep fallback to defaults
- Test thoroughly

### Step 4: Remove Old Overrides
- Remove hardcoded date overrides from workflow
- All scheduling through `blog-schedule.json`
- Clean up old code

### Step 5: Enable Weekly Automation
- Activate weekly planning workflow
- Monitor for first few weeks
- Adjust as needed

---

## Success Metrics

1. **Planning Horizon**: Maintain 7+ days of approved topics
2. **User Engagement**: User reviews/edits 80%+ of proposals
3. **Topic Quality**: 90%+ of generated topics match approved topics
4. **Automation**: 70%+ of topics auto-approved (if `requireApproval: false`)
5. **Reliability**: 100% of scheduled blogs generate successfully

---

## Risk Mitigation

### Risk 1: AI Proposals Are Poor Quality
**Mitigation**: 
- Start with conservative proposals (close to defaults)
- Allow easy editing/overriding
- Learn from user edits over time

### Risk 2: Schedule File Gets Corrupted
**Mitigation**:
- JSON schema validation
- Git version control (can revert)
- Fallback to defaults in workflow

### Risk 3: User Forgets to Review
**Mitigation**:
- PR notifications
- Slack/email alerts (future)
- Auto-approve if `requireApproval: false`

### Risk 4: Planning Workflow Fails
**Mitigation**:
- Manual trigger option
- Fallback to defaults
- Alert on failure

---

## Cost Considerations

### Zero-Cost Implementation
- **Template-based proposals**: No external APIs required
- **GitHub Actions**: Within free tier (2,000 min/month)
- **Storage**: Included in GitHub repository
- **Total: $0/month**

### Optional AI Enhancement
- **GitHub Copilot API**: $0 (free for public repos)
- **GPT-3.5-turbo**: $0.04-0.08/month
- **GPT-4**: $0.40-0.60/month
- **Claude Haiku**: $0.08-0.12/month

**Recommendation**: Start with template-based (zero cost), upgrade to AI only if needed.

See `enhanced-blog-planning-system-cost-analysis.md` for detailed cost breakdown.

## Requirements Summary

✅ **Planning Horizon**: Configurable, default 14 days (2 weeks)  
✅ **Auto-Approval**: Default enabled (can be disabled)  
✅ **Proposals**: 1 primary + 2-3 alternatives per day  
✅ **Research Notes**: Can be added prior to blog generation  
✅ **Cost**: Zero-cost template-based implementation (optional AI upgrade)

---

## Next Steps

1. **Review this plan** with user
2. **Get approval** for approach and phases
3. **Start Phase 1** implementation
4. **Iterate** based on feedback

---

**Document Version**: 1.0  
**Created**: 2025-11-07  
**Status**: Draft - Awaiting Review

