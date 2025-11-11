# Debug Commands for generate-terraform-resource-list.js

## Current Situation
The script is looping through resources and hitting line 184 repeatedly. This means:
- The loop is working
- Resources are being processed
- Likely hanging inside `getResourceARN()` function

## Next Steps in Debugger

### 1. Check current resource
```
p resource
p i
```

### 2. Set breakpoint inside getResourceARN (where it likely hangs)
```
sb(96)   // Inside getResourceARN - JSON terraform state show
sb(110)  // Inside getResourceARN - Text terraform state show
```

### 3. Continue and see where it hangs
```
c        // Continue - will stop at getResourceARN breakpoint
```

### 4. When it hangs, check:
```
p resourceAddress
p resourceType
p resourceName
```

### 5. Skip to next resource if one is hanging
```
c        // Let it hang, then Ctrl+C
// Or set breakpoint after getResourceARN call
sb(221)  // After getResourceARN returns
```

## Alternative: Add timeout/error handling

If specific resources are hanging, we can:
1. Add timeout wrapper around execSync
2. Skip resources that take too long
3. Log which resources are problematic

