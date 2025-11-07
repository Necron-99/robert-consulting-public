#!/usr/bin/env node

/**
 * Blog Topic Proposal Generator (Template-Based)
 * Generates topic proposals for upcoming blog posts using template patterns
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Topic templates organized by day theme
const TOPIC_TEMPLATES = {
  monday: {
    primary: [
      { topic: "AWS Cost Optimization Strategies", focus: "Practical approaches to reducing AWS costs through right-sizing, reserved instances, and intelligent resource management", keywords: "AWS cost optimization, cost management, reserved instances, right-sizing, cost analysis" },
      { topic: "AWS Lambda Best Practices", focus: "Optimizing Lambda functions for performance, cost, and reliability in serverless architectures", keywords: "AWS Lambda, serverless, function optimization, cold starts, performance tuning" },
      { topic: "Amazon S3 Storage Optimization", focus: "Strategies for optimizing S3 storage costs, lifecycle policies, and intelligent tiering", keywords: "S3, storage optimization, lifecycle policies, intelligent tiering, cost reduction" },
      { topic: "AWS Well-Architected Framework", focus: "Implementing AWS Well-Architected Framework principles for operational excellence, security, and cost optimization", keywords: "Well-Architected Framework, AWS best practices, architecture review, operational excellence" },
      { topic: "CloudFront CDN Optimization", focus: "Maximizing CloudFront performance and minimizing costs through caching strategies and origin optimization", keywords: "CloudFront, CDN, caching, performance optimization, content delivery" },
      { topic: "AWS Security Best Practices", focus: "Implementing comprehensive security controls across AWS services including IAM, encryption, and monitoring", keywords: "AWS security, IAM, encryption, security best practices, compliance" },
      { topic: "Multi-Region AWS Architecture", focus: "Designing and implementing resilient multi-region architectures for high availability and disaster recovery", keywords: "multi-region, high availability, disaster recovery, AWS architecture, resilience" }
    ],
    alternatives: [
      { topic: "EC2 Instance Optimization", focus: "Selecting and optimizing EC2 instances for performance and cost efficiency", keywords: "EC2, instance types, optimization, cost efficiency" },
      { topic: "AWS Networking Fundamentals", focus: "Understanding VPC, subnets, routing, and network security in AWS", keywords: "VPC, networking, subnets, routing, AWS networking" },
      { topic: "AWS Monitoring and Observability", focus: "Implementing comprehensive monitoring with CloudWatch, X-Ray, and other AWS observability tools", keywords: "CloudWatch, monitoring, observability, AWS X-Ray, logging" }
    ]
  },
  tuesday: {
    primary: [
      { topic: "CI/CD Pipeline Optimization", focus: "Strategies for optimizing CI/CD pipelines for speed, reliability, and cost efficiency", keywords: "CI/CD, pipeline optimization, DevOps automation, build performance, deployment speed" },
      { topic: "GitHub Actions Best Practices", focus: "Advanced GitHub Actions workflows, optimization techniques, and security best practices", keywords: "GitHub Actions, CI/CD, automation, workflows, GitHub" },
      { topic: "Infrastructure Automation Patterns", focus: "Common automation patterns for infrastructure provisioning, configuration, and deployment", keywords: "automation, infrastructure, patterns, DevOps, configuration management" },
      { topic: "DevOps Culture and Practices", focus: "Building effective DevOps culture, collaboration strategies, and team practices", keywords: "DevOps culture, collaboration, team practices, agile, continuous improvement" },
      { topic: "Container CI/CD Strategies", focus: "Implementing CI/CD pipelines for containerized applications with Docker and Kubernetes", keywords: "containers, CI/CD, Docker, Kubernetes, container pipelines" },
      { topic: "Infrastructure Monitoring and Alerting", focus: "Setting up comprehensive monitoring and alerting for infrastructure and applications", keywords: "monitoring, alerting, infrastructure monitoring, observability, DevOps" },
      { topic: "Deployment Strategies and Rollbacks", focus: "Implementing blue-green, canary, and rolling deployment strategies with automated rollback capabilities", keywords: "deployment strategies, blue-green, canary, rollback, zero-downtime" }
    ],
    alternatives: [
      { topic: "Configuration Management Tools", focus: "Comparing and using tools like Ansible, Puppet, and Chef for infrastructure automation", keywords: "configuration management, Ansible, Puppet, Chef, automation" },
      { topic: "DevOps Metrics and KPIs", focus: "Measuring DevOps success with key metrics and performance indicators", keywords: "DevOps metrics, KPIs, DORA metrics, performance measurement" },
      { topic: "Infrastructure Testing Strategies", focus: "Testing infrastructure code and configurations for reliability and compliance", keywords: "infrastructure testing, testing strategies, compliance, reliability" }
    ]
  },
  wednesday: {
    primary: [
      { topic: "Vulnerability Management Best Practices", focus: "Implementing comprehensive vulnerability scanning, assessment, and remediation workflows", keywords: "vulnerability management, security scanning, remediation, security automation" },
      { topic: "SAST and DAST Integration", focus: "Integrating Static and Dynamic Application Security Testing into CI/CD pipelines", keywords: "SAST, DAST, security testing, application security, CI/CD security" },
      { topic: "Secrets Management in DevOps", focus: "Secure secrets management strategies using tools like AWS Secrets Manager, HashiCorp Vault, and GitHub Secrets", keywords: "secrets management, security, AWS Secrets Manager, Vault, credential management" },
      { topic: "Security Compliance Automation", focus: "Automating security compliance checks and reporting for SOC 2, ISO 27001, and other standards", keywords: "compliance, security automation, SOC 2, ISO 27001, compliance automation" },
      { topic: "Threat Detection and Response", focus: "Implementing automated threat detection, incident response, and security monitoring", keywords: "threat detection, incident response, security monitoring, SIEM, security automation" },
      { topic: "Infrastructure Security Hardening", focus: "Hardening infrastructure components including servers, containers, and cloud resources", keywords: "security hardening, infrastructure security, compliance, security best practices" },
      { topic: "DevSecOps Pipeline Implementation", focus: "Building security into CI/CD pipelines from the start with automated security checks", keywords: "DevSecOps, security pipeline, CI/CD security, shift-left security" }
    ],
    alternatives: [
      { topic: "Container Security Best Practices", focus: "Securing containerized applications and container registries", keywords: "container security, Docker security, Kubernetes security, container scanning" },
      { topic: "Cloud Security Posture Management", focus: "Managing and improving cloud security posture across AWS, Azure, and GCP", keywords: "cloud security, CSPM, security posture, cloud compliance" },
      { topic: "Security Incident Response", focus: "Building effective incident response procedures and automation for security events", keywords: "incident response, security incidents, automation, security operations" }
    ]
  },
  thursday: {
    primary: [
      { topic: "Terraform State Management", focus: "Best practices for managing Terraform state files, remote backends, and state locking", keywords: "Terraform, state management, remote backend, state locking, infrastructure as code" },
      { topic: "Terraform Modules and Reusability", focus: "Creating reusable Terraform modules for common infrastructure patterns", keywords: "Terraform modules, infrastructure patterns, code reuse, IaC best practices" },
      { topic: "OpenTofu vs Terraform", focus: "Comparing OpenTofu and Terraform, migration strategies, and when to use each", keywords: "OpenTofu, Terraform, comparison, migration, infrastructure as code" },
      { topic: "Terragrunt for DRY Infrastructure", focus: "Using Terragrunt to reduce duplication and manage complex Terraform configurations", keywords: "Terragrunt, Terraform, DRY principles, configuration management" },
      { topic: "Infrastructure Testing with Terratest", focus: "Writing and running tests for infrastructure code using Terratest and other testing frameworks", keywords: "infrastructure testing, Terratest, IaC testing, test automation" },
      { topic: "CloudFormation vs Terraform", focus: "Comparing AWS CloudFormation and Terraform for infrastructure provisioning", keywords: "CloudFormation, Terraform, comparison, AWS, infrastructure as code" },
      { topic: "IaC Security and Compliance", focus: "Implementing security scanning and compliance checks for infrastructure code", keywords: "IaC security, infrastructure security, compliance, security scanning" }
    ],
    alternatives: [
      { topic: "Terraform Workspaces and Environments", focus: "Managing multiple environments with Terraform workspaces and best practices", keywords: "Terraform workspaces, environments, multi-environment, infrastructure management" },
      { topic: "Infrastructure Drift Detection", focus: "Detecting and managing infrastructure drift in Terraform-managed environments", keywords: "drift detection, infrastructure drift, Terraform, configuration management" },
      { topic: "Pulumi: Code-Based Infrastructure", focus: "Using Pulumi to define infrastructure using familiar programming languages", keywords: "Pulumi, infrastructure as code, programming languages, IaC" }
    ]
  },
  friday: {
    primary: [
      { topic: "Kubernetes Deployment Strategies", focus: "Implementing rolling updates, blue-green, and canary deployments in Kubernetes", keywords: "Kubernetes, deployment strategies, rolling updates, blue-green, canary" },
      { topic: "Kubernetes Resource Management", focus: "Optimizing resource requests, limits, and autoscaling in Kubernetes clusters", keywords: "Kubernetes, resource management, autoscaling, optimization, cluster management" },
      { topic: "Docker Best Practices", focus: "Optimizing Docker images, multi-stage builds, and container security", keywords: "Docker, container optimization, multi-stage builds, container security" },
      { topic: "GitOps with ArgoCD", focus: "Implementing GitOps workflows using ArgoCD for Kubernetes deployments", keywords: "GitOps, ArgoCD, Kubernetes, continuous deployment, GitOps patterns" },
      { topic: "Container Orchestration Patterns", focus: "Common patterns for deploying and managing containerized applications at scale", keywords: "container orchestration, Kubernetes patterns, deployment patterns, microservices" },
      { topic: "Kubernetes Security Best Practices", focus: "Securing Kubernetes clusters, pods, and container workloads", keywords: "Kubernetes security, pod security, cluster security, container security" },
      { topic: "Service Mesh with Istio", focus: "Implementing service mesh patterns for microservices communication and observability", keywords: "service mesh, Istio, microservices, observability, traffic management" }
    ],
    alternatives: [
      { topic: "Kubernetes Monitoring and Observability", focus: "Implementing comprehensive monitoring for Kubernetes clusters and applications", keywords: "Kubernetes monitoring, observability, Prometheus, Grafana, cluster monitoring" },
      { topic: "Container Registry Management", focus: "Managing container registries, image scanning, and security best practices", keywords: "container registry, Docker registry, image scanning, container security" },
      { topic: "Kubernetes Networking Deep Dive", focus: "Understanding Kubernetes networking, CNI plugins, and network policies", keywords: "Kubernetes networking, CNI, network policies, cluster networking" }
    ]
  }
};

// Read existing schedule
function readSchedule() {
  const schedulePath = path.join(__dirname, '..', 'blog-schedule.json');
  try {
    const content = fs.readFileSync(schedulePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error reading blog-schedule.json: ${error.message}`);
    process.exit(1);
  }
}

// Write schedule
function writeSchedule(schedule) {
  const schedulePath = path.join(__dirname, '..', 'blog-schedule.json');
  schedule.lastUpdated = new Date().toISOString();
  fs.writeFileSync(schedulePath, JSON.stringify(schedule, null, 2) + '\n');
}

// Get recent blog topics from blog.js to avoid repetition
function getRecentTopics() {
  const blogJsPath = path.join(__dirname, '..', 'website', 'js', 'blog.js');
  try {
    const content = fs.readFileSync(blogJsPath, 'utf8');
    const topics = [];
    // Extract titles from blog.js (simple regex match)
    const titleMatches = content.matchAll(/title:\s*['"]([^'"]+)['"]/g);
    for (const match of titleMatches) {
      topics.push(match[1].toLowerCase());
    }
    return topics;
  } catch (error) {
    console.warn(`Warning: Could not read recent topics: ${error.message}`);
    return [];
  }
}

// Check if topic is too similar to recent topics
function isTopicRecent(topic, recentTopics) {
  const topicLower = topic.toLowerCase();
  for (const recent of recentTopics) {
    // Simple similarity check - if more than 50% of words match, consider it recent
    const topicWords = new Set(topicLower.split(/\s+/));
    const recentWords = new Set(recent.toLowerCase().split(/\s+/));
    const intersection = new Set([...topicWords].filter(x => recentWords.has(x)));
    const similarity = intersection.size / Math.max(topicWords.size, recentWords.size);
    if (similarity > 0.5) {
      return true;
    }
  }
  return false;
}

// Generate date for a day of week
function getDateForDay(dayName, startDate = new Date()) {
  const dayMap = { monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5 };
  const targetDay = dayMap[dayName.toLowerCase()];
  if (!targetDay) return null;
  
  const date = new Date(startDate);
  const currentDay = date.getDay(); // 0 = Sunday, 1 = Monday, etc.
  const daysUntilTarget = (targetDay - currentDay + 7) % 7;
  if (daysUntilTarget === 0 && currentDay !== 0) {
    // If it's already that day, move to next week
    date.setDate(date.getDate() + 7);
  } else {
    date.setDate(date.getDate() + daysUntilTarget);
  }
  return date.toISOString().split('T')[0];
}

// Generate proposals for a specific date range
function generateProposals(horizonDays = 14) {
  const schedule = readSchedule();
  const recentTopics = getRecentTopics();
  const today = new Date();
  const proposals = [];
  
  // Generate for next N weekdays
  let currentDate = new Date(today);
  let daysGenerated = 0;
  const dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  
  while (daysGenerated < horizonDays) {
    const dayOfWeek = currentDate.getDay();
    
    // Skip weekends
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      currentDate.setDate(currentDate.getDate() + 1);
      continue;
    }
    
    const dayName = dayNames[dayOfWeek - 1];
    const dateStr = currentDate.toISOString().split('T')[0];
    
    // Check if already scheduled
    const existing = schedule.schedule.find(s => s.date === dateStr);
    if (existing && existing.status !== 'proposed') {
      currentDate.setDate(currentDate.getDate() + 1);
      continue;
    }
    
    // Get templates for this day
    const templates = TOPIC_TEMPLATES[dayName];
    if (!templates) {
      currentDate.setDate(currentDate.getDate() + 1);
      continue;
    }
    
    // Select primary topic (avoiding recent ones)
    let primaryTopic = null;
    const shuffledPrimary = [...templates.primary].sort(() => Math.random() - 0.5);
    for (const template of shuffledPrimary) {
      if (!isTopicRecent(template.topic, recentTopics)) {
        primaryTopic = template;
        break;
      }
    }
    
    // Fallback to first template if all are recent
    if (!primaryTopic) {
      primaryTopic = templates.primary[0];
    }
    
    // Select 2-3 alternatives
    const alternatives = [];
    const shuffledAlt = [...templates.alternatives].sort(() => Math.random() - 0.5);
    for (const alt of shuffledAlt.slice(0, 3)) {
      if (!isTopicRecent(alt.topic, recentTopics)) {
        alternatives.push(alt);
      }
    }
    
    // Determine category, icon, tags based on day
    const categoryMap = {
      monday: { category: 'aws', icon: '☁️', tags: ['AWS', 'Cloud Infrastructure', 'Cloud Services'] },
      tuesday: { category: 'devops', icon: '⚙️', tags: ['DevOps', 'Automation', 'CI/CD'] },
      wednesday: { category: 'security', icon: '🔒', tags: ['Security', 'DevSecOps', 'Threat Detection'] },
      thursday: { category: 'infrastructure', icon: '🏗️', tags: ['Infrastructure as Code', 'IaC', 'Terraform'] },
      friday: { category: 'containers', icon: '🐳', tags: ['Kubernetes', 'Docker', 'Container Orchestration'] }
    };
    
    const metadata = categoryMap[dayName];
    
    const proposal = {
      date: dateStr,
      day: dayName,
      status: schedule.settings.requireApproval ? 'proposed' : 'approved',
      topic: primaryTopic.topic,
      focus: primaryTopic.focus,
      keywords: primaryTopic.keywords,
      category: metadata.category,
      icon: metadata.icon,
      tags: metadata.tags,
      readTime: "10 min read",
      notes: "",
      researchNotes: "",
      suggestedBy: "system",
      suggestedAt: new Date().toISOString(),
      approvedBy: schedule.settings.requireApproval ? null : "system",
      approvedAt: schedule.settings.requireApproval ? null : new Date().toISOString(),
      alternatives: alternatives.map(alt => ({
        topic: alt.topic,
        focus: alt.focus,
        keywords: alt.keywords
      }))
    };
    
    proposals.push(proposal);
    daysGenerated++;
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  return proposals;
}

// Main function
function main() {
  const args = process.argv.slice(2);
  const horizonArg = args.find(arg => arg.startsWith('--horizon'));
  const horizonDays = horizonArg ? parseInt(horizonArg.split('=')[1]) : 14;
  
  console.log(`📅 Generating blog topic proposals for next ${horizonDays} days...`);
  
  const schedule = readSchedule();
  const proposals = generateProposals(horizonDays);
  
  // Merge with existing schedule (update existing, add new)
  for (const proposal of proposals) {
    const existingIndex = schedule.schedule.findIndex(s => s.date === proposal.date);
    if (existingIndex >= 0) {
      // Update existing if it's proposed or doesn't exist
      if (schedule.schedule[existingIndex].status === 'proposed' || !schedule.schedule[existingIndex].status) {
        schedule.schedule[existingIndex] = proposal;
      }
    } else {
      schedule.schedule.push(proposal);
    }
  }
  
  // Sort by date
  schedule.schedule.sort((a, b) => a.date.localeCompare(b.date));
  
  writeSchedule(schedule);
  
  console.log(`✅ Generated ${proposals.length} topic proposals`);
  console.log(`📝 Schedule now contains ${schedule.schedule.length} entries`);
  
  // Show summary
  console.log('\n📋 Generated Proposals:');
  for (const proposal of proposals.slice(0, 5)) {
    console.log(`  ${proposal.date} (${proposal.day}): ${proposal.topic}`);
  }
  if (proposals.length > 5) {
    console.log(`  ... and ${proposals.length - 5} more`);
  }
}

main();

