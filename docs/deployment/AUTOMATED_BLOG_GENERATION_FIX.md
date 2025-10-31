## Automated Blog Generation Fix Summary

- **Workflow Guardrails**: Added change detection in `automated-blog-generation.yml` so downstream steps (S3 upload, CloudFront invalidation, git commit) only run when a blog post actually changes. This prevents scheduled runs from failing with empty commits.
- **Commit Safety**: Commit step now stages just the generated post and skips pushing when no staged changes remain.
- **Submodule Cleanup Fix**: Restored the `.gitmodules` definition for `plex-recommendations-migration` so GitHub Actions post-job cleanup no longer errors on missing submodule metadata.
- **Content Script Improvements**: `scripts/generate-detailed-blog.sh` now enables shell expansion for dynamic values, uses the correct blog stylesheet path, and enforces `set -euo pipefail` for safer execution.

### Manual Verification

1. From the repo root, run `bash scripts/generate-detailed-blog.sh monday "AWS Services and Updates" "Latest AWS updates" "aws,cloud" "$(date +%Y-%m-%d)" "website/blog-posts/test-blog.html"`.
2. Confirm the generated HTML shows the correct ISO date and references `../blog/css/blog.css`.
3. Remove the test file after inspection to keep the workspace clean.

### Operational Notes

- Re-running the GitHub workflow on the same day now exits gracefully without uploading or committing when no changes are detected.
- Existing posts created before this fix still have the old static date string; regenerate them if you want live dates.
