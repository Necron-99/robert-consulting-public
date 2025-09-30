# Dependabot Configuration Guide

## 🔧 Overview

This repository is configured with **Dependabot** to automatically monitor dependencies for security vulnerabilities and keep them updated. Dependabot will create pull requests when updates are available.

## 📋 What Dependabot Monitors

### 1. **NPM Dependencies** (`/website`)
- **Location**: `website/package.json`
- **Schedule**: Every Monday at 9:00 AM EST
- **Updates**: Minor and patch versions
- **Security**: Automatic security updates
- **Labels**: `dependencies`, `automated`, `security`

### 2. **GitHub Actions** (Repository root)
- **Location**: `.github/workflows/`
- **Schedule**: Every Monday at 9:00 AM EST
- **Updates**: Action versions and security patches
- **Labels**: `github-actions`, `automated`, `ci-cd`

### 3. **Terraform Providers** (`/terraform`)
- **Location**: `terraform/` directory
- **Schedule**: Every Monday at 9:00 AM EST
- **Updates**: Provider versions and security patches
- **Labels**: `terraform`, `infrastructure`, `automated`, `iac`

### 4. **Docker Images** (Repository root)
- **Location**: Any `Dockerfile` files
- **Schedule**: Every Monday at 9:00 AM EST
- **Updates**: Base image versions and security patches
- **Labels**: `docker`, `automated`, `containers`

## 🚀 How It Works

### **Automatic Security Alerts**
- Dependabot automatically scans for known vulnerabilities
- Creates security alerts in GitHub Security tab
- Generates pull requests for security updates

### **Weekly Dependency Updates**
- Scans all configured package ecosystems
- Creates pull requests for available updates
- Groups related updates together
- Includes detailed changelog information

### **Smart Update Strategy**
- **Minor & Patch Updates**: Automatically included
- **Major Updates**: Currently ignored (can be enabled later)
- **Security Updates**: Always prioritized
- **Grouped Updates**: Related dependencies updated together

## 📊 Monitoring & Management

### **GitHub Security Tab**
1. Go to your repository
2. Click **Security** tab
3. View **Dependabot alerts**
4. See vulnerability details and remediation steps

### **Pull Requests**
- Dependabot creates PRs with clear titles
- Includes detailed changelog information
- Shows what changed and why
- Provides merge instructions

### **Labels & Organization**
- **`dependencies`**: NPM package updates
- **`github-actions`**: CI/CD workflow updates
- **`terraform`**: Infrastructure updates
- **`docker`**: Container updates
- **`automated`**: All Dependabot PRs
- **`security`**: Security-related updates

## 🔍 Reviewing Dependabot PRs

### **What to Look For**
1. **Security Updates**: Always review and merge quickly
2. **Breaking Changes**: Check changelog for breaking changes
3. **Compatibility**: Ensure updates work with your code
4. **Testing**: Run tests before merging

### **Best Practices**
- **Review PRs weekly** (they're created on Mondays)
- **Merge security updates immediately**
- **Test major updates** in development first
- **Keep an eye on the Security tab**

## ⚙️ Configuration Details

### **Update Schedule**
- **Frequency**: Weekly (Mondays)
- **Time**: 9:00 AM EST
- **Timezone**: America/New_York

### **Pull Request Limits**
- **NPM**: 10 PRs max
- **GitHub Actions**: 5 PRs max
- **Terraform**: 5 PRs max
- **Docker**: 3 PRs max

### **Commit Message Format**
- **NPM**: `deps: update package-name`
- **GitHub Actions**: `ci: update action-name`
- **Terraform**: `terraform: update provider-name`
- **Docker**: `docker: update image-name`

## 🛡️ Security Features

### **Automatic Security Scanning**
- Scans for known vulnerabilities
- Creates security alerts
- Prioritizes security updates
- Includes CVE information

### **Security Update Priority**
- Security updates are created immediately
- Not limited by weekly schedule
- Include detailed vulnerability information
- Provide remediation guidance

## 📈 Benefits

### **Security**
- ✅ **Automatic vulnerability detection**
- ✅ **Immediate security updates**
- ✅ **CVE tracking and alerts**
- ✅ **Security best practices**

### **Maintenance**
- ✅ **Reduced manual dependency management**
- ✅ **Automated update process**
- ✅ **Clear update documentation**
- ✅ **Grouped related updates**

### **Development**
- ✅ **Latest features and fixes**
- ✅ **Improved performance**
- ✅ **Better compatibility**
- ✅ **Reduced technical debt**

## 🔧 Customization Options

### **Enable Major Updates**
To enable major version updates, remove this section from `.github/dependabot.yml`:
```yaml
ignore:
  - dependency-name: "*"
    update-types: ["version-update:semver-major"]
```

### **Change Update Schedule**
Modify the `schedule` section:
```yaml
schedule:
  interval: "daily"  # or "weekly", "monthly"
  day: "monday"     # for weekly
  time: "09:00"
  timezone: "America/New_York"
```

### **Add More Ecosystems**
Add new package ecosystems:
```yaml
- package-ecosystem: "pip"
  directory: "/"
  schedule:
    interval: "weekly"
```

## 🚨 Troubleshooting

### **Common Issues**

#### **Dependabot Not Running**
- Check if `.github/dependabot.yml` exists
- Verify file syntax is correct
- Ensure repository has dependencies

#### **Too Many PRs**
- Reduce `open-pull-requests-limit`
- Enable grouping with `groups`
- Ignore specific dependencies

#### **Failed Updates**
- Check for breaking changes
- Review dependency compatibility
- Test updates locally first

### **Getting Help**
- **GitHub Docs**: [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- **Security Tab**: Check for alerts and guidance
- **PR Comments**: Dependabot provides detailed information

## 📚 Additional Resources

### **GitHub Security Features**
- **Security Advisories**: Track vulnerabilities
- **Dependency Graph**: Visualize dependencies
- **Security Updates**: Automated security patches
- **Secret Scanning**: Detect exposed secrets

### **Best Practices**
- **Regular Reviews**: Check PRs weekly
- **Security First**: Prioritize security updates
- **Testing**: Test updates before merging
- **Documentation**: Keep changelogs updated

## 🎯 Next Steps

1. **Enable Dependabot**: Already configured! ✅
2. **Review Security Tab**: Check for existing alerts
3. **Monitor PRs**: Review weekly updates
4. **Merge Security Updates**: Prioritize security patches
5. **Test Updates**: Ensure compatibility

**Your repository is now protected with automated dependency monitoring and security alerts!** 🚀🔒
