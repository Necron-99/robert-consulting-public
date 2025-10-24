/**
 * Automated CloudFront Cache Invalidation
 * This script can be integrated into your deployment process
 */

const AWS = require('aws-sdk');

class CloudFrontInvalidator {
  constructor() {
    this.cloudfront = new AWS.CloudFront();
    this.distributionId = 'E36DBYPHUUKB3V'; // Your distribution ID
  }

  /**
     * Invalidate specific paths
     * @param {string[]} paths - Array of paths to invalidate
     * @returns {Promise<Object>} - Invalidation result
     */
  async invalidatePaths(paths = ['/*']) {
    try {
      const params = {
        DistributionId: this.distributionId,
        InvalidationBatch: {
          Paths: {
            Quantity: paths.length,
            Items: paths
          },
          CallerReference: `auto-invalidate-${Date.now()}`
        }
      };

      const result = await this.cloudfront.createInvalidation(params).promise();
      console.log('✅ CloudFront invalidation created:', result.Invalidation.Id);
      return result;
    } catch (error) {
      console.error('❌ Failed to invalidate CloudFront cache:', error);
      throw error;
    }
  }

  /**
     * Invalidate all files
     * @returns {Promise<Object>} - Invalidation result
     */
  async invalidateAll() {
    return this.invalidatePaths(['/*']);
  }

  /**
     * Invalidate specific files
     * @param {string[]} files - Array of file paths to invalidate
     * @returns {Promise<Object>} - Invalidation result
     */
  async invalidateFiles(files) {
    const paths = files.map(file => `/${file}`);
    return this.invalidatePaths(paths);
  }

  /**
     * Check invalidation status
     * @param {string} invalidationId - Invalidation ID to check
     * @returns {Promise<Object>} - Invalidation status
     */
  async checkInvalidationStatus(invalidationId) {
    try {
      const params = {
        DistributionId: this.distributionId,
        Id: invalidationId
      };

      const result = await this.cloudfront.getInvalidation(params).promise();
      return result.Invalidation;
    } catch (error) {
      console.error('❌ Failed to check invalidation status:', error);
      throw error;
    }
  }
}

// Export for use in other scripts
module.exports = CloudFrontInvalidator;

// CLI usage example
if (require.main === module) {
  const invalidator = new CloudFrontInvalidator();

  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
  case 'all':
    invalidator.invalidateAll()
      .then(result => console.log('Invalidation created:', result.Invalidation.Id))
      .catch(error => console.error('Error:', error));
    break;

  case 'files': {
    const files = args.slice(1);
    invalidator.invalidateFiles(files)
      .then(result => console.log('Invalidation created:', result.Invalidation.Id))
      .catch(error => console.error('Error:', error));
    break;
  }

  case 'status': {
    const invalidationId = args[1];
    invalidator.checkInvalidationStatus(invalidationId)
      .then(status => console.log('Status:', status.Status))
      .catch(error => console.error('Error:', error));
    break;
  }

  default:
    console.log('Usage:');
    console.log('  node auto-invalidate.js all');
    console.log('  node auto-invalidate.js files index.html learning.html');
    console.log('  node auto-invalidate.js status <distribution-id>');
  }
}
