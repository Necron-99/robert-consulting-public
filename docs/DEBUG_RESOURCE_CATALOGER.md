# Debugging Resource Cataloger Issues

## Current Issues

1. **IAM Permissions Fixed** ✅
   - Added `tag:GetResources` permission to IAM policy
   - Lambda now runs without permission errors

2. **Resource Discovery Issue** ❌
   - Lambda discovers 0 resources
   - Resource Groups Tagging API returns resources, but they're filtered out
   - Issue: ARN matching between Tagging API and Terraform ARN list

3. **ARN List Generation Hanging** ❌
   - Script hangs when processing resources
   - Likely hanging on `terraform state show` for specific resources

## Debugging Steps

### Using Node.js Inspector

1. **Start the debugger:**
   ```bash
   node inspect scripts/generate-terraform-resource-list.js
   ```

2. **Set breakpoints at key locations:**
   - Line 65: `getTerraformState()` - Check if state list completes
   - Line 178: Start of resource processing loop
   - Line 215: Before `getResourceARN()` call
   - Line 91: Inside `getResourceARN()` - JSON format attempt
   - Line 99: Inside `getResourceARN()` - Text format fallback

3. **Continue execution:**
   - `c` or `cont` - Continue to next breakpoint
   - `n` - Next line
   - `s` - Step into function
   - `p <variable>` - Print variable value

4. **Watch for:**
   - Which resource causes the hang
   - How long `terraform state show` takes
   - If JSON format works or falls back to text

### Potential Hanging Points

1. **`terraform state list`** - If state is large or remote
2. **`terraform state show -json`** - If resource has complex state
3. **`terraform state show` (text)** - If resource state is very large
4. **Specific resource types** - Some resources may have problematic state

### Quick Fix Options

1. **Skip problematic resources:**
   - Add try-catch with timeout
   - Skip resources that take > 10 seconds
   - Log which resources are slow

2. **Process in batches:**
   - Process only specific resource types first
   - Skip modules/data sources entirely

3. **Use Terraform state directly:**
   - Read state file directly instead of using `terraform state show`
   - Faster but requires state file access

## Next Steps

1. Identify which resource causes the hang
2. Add timeout/retry logic for slow resources
3. Optimize ARN extraction for common resource types
4. Consider caching or incremental updates

