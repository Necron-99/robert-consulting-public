# Blog Topic Management Guide

## Overview

The enhanced blog planning system allows you to plan blog topics at least a week in advance, review and edit proposals, and schedule specific topics for specific dates.

## Quick Start

### View Upcoming Schedule

```bash
node scripts/manage-blog-schedule.js view --days=14
```

### Generate Topic Proposals

```bash
node scripts/generate-blog-proposals.js --horizon=14
```

### Schedule a Custom Topic

```bash
node scripts/manage-blog-schedule.js suggest 2025-11-10 \
  --topic "AWS Cost Management" \
  --focus "Practical strategies to keep AWS costs in check" \
  --keywords "AWS cost optimization, cost management"
```

### Add Research Notes

```bash
node scripts/manage-blog-schedule.js add-research 2025-11-10 \
  --file "docs/blog-research/monday-aws-cost-management.md"
```

### Switch to Alternative Topic

```bash
node scripts/manage-blog-schedule.js switch 2025-11-11 --alternative=1
```

### Edit a Topic

```bash
node scripts/manage-blog-schedule.js edit 2025-11-10 \
  --topic "New Topic" \
  --focus "New focus" \
  --keywords "new, keywords"
```

## How It Works

### Automatic Proposal Generation

Every Sunday at 6 PM, the `blog-planning.yml` workflow runs and:
1. Generates topic proposals for the next 14 days (configurable)
2. Auto-approves proposals (if `requireApproval: false`)
3. Commits proposals to `blog-schedule.json`

### Daily Blog Generation

Each weekday at 9 AM, the `automated-blog-generation.yml` workflow:
1. Checks `blog-schedule.json` for a scheduled topic for today
2. If found and status is "approved", uses that topic
3. Otherwise, falls back to default topic for the day of week
4. Generates the blog post
5. Updates status to "generated"

### Topic Status Flow

```
proposed → approved → generated
    ↓         ↓
  skipped   skipped
```

## Configuration

Edit `blog-schedule.json` settings:

```json
{
  "settings": {
    "planningHorizonDays": 14,      // How many days to plan ahead
    "autoGenerateProposals": true,  // Auto-generate proposals
    "requireApproval": false,       // Auto-approve proposals
    "regenerateThreshold": 7,       // Regenerate when < 7 days remain
    "proposalMethod": "template"    // Use template-based generation
  }
}
```

Or use the CLI:

```bash
node scripts/manage-blog-schedule.js config --horizon=21 --auto-approve=true
```

## File Structure

- `blog-schedule.json` - Main schedule file with all topics
- `scripts/generate-blog-proposals.js` - Proposal generator
- `scripts/manage-blog-schedule.js` - Management CLI
- `docs/blog-research/` - Research notes directory

## Best Practices

1. **Review Weekly**: Check proposals every Sunday after they're generated
2. **Plan Ahead**: Schedule specific topics at least a week in advance
3. **Add Research**: Link research notes to topics before generation
4. **Use Alternatives**: Switch to alternatives if primary topic doesn't fit
5. **Edit Freely**: Edit any topic before it's generated

## Troubleshooting

### Proposals Not Generating

Check that `blog-schedule.json` exists and is valid JSON:
```bash
jq . blog-schedule.json
```

### Topic Not Used

Ensure the topic status is "approved" and the date matches:
```bash
node scripts/manage-blog-schedule.js view --days=7
```

### Research Notes Not Found

Verify the file path is correct and relative to repo root:
```bash
ls -la docs/blog-research/monday-aws-cost-management.md
```

