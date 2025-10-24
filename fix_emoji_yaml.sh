#!/bin/bash

echo "🔧 === FIXING EMOJI CHARACTERS IN YAML FILES ==="
echo "📝 Replacing all emoji characters with simple text to fix YAML parsing"

# Fix issue-feedback-system.yml
echo "📝 Fixing issue-feedback-system.yml..."

# Replace emoji characters with simple text
sed -i 's/📊/ANALYSIS/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🔧/SETUP/g' .github/workflows/issue-feedback-system.yml
sed -i 's/⏰/TIME/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🚨/ALERT/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🔒/SECURITY/g' .github/workflows/issue-feedback-system.yml
sed -i 's/⚠️/WARNING/g' .github/workflows/issue-feedback-system.yml
sed -i 's/👤/USER/g' .github/workflows/issue-feedback-system.yml
sed -i 's/📝/NOTE/g' .github/workflows/issue-feedback-system.yml
sed -i 's/💬/COMMENT/g' .github/workflows/issue-feedback-system.yml
sed -i 's/📋/DOCUMENT/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🔍/SEARCH/g' .github/workflows/issue-feedback-system.yml
sed -i 's/✅/SUCCESS/g' .github/workflows/issue-feedback-system.yml
sed -i 's/❌/ERROR/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🎯/TARGET/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🚀/LAUNCH/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🏷️/LABEL/g' .github/workflows/issue-feedback-system.yml
sed -i 's/🔴/RED/g' .github/workflows/issue-feedback-system.yml

echo "✅ issue-feedback-system.yml fixed"

echo "🎯 All emoji characters replaced with simple text!"
echo "✅ YAML syntax errors should now be resolved!"
