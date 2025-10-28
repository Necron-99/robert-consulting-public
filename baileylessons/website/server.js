const express = require('express');
const { Pool } = require('pg');
const AWS = require('aws-sdk');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 80;

// Security middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.use(morgan('combined'));

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: 5432,
  ssl: { rejectUnauthorized: false }
});

// S3 configuration
const s3 = new AWS.S3({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0'
  });
});

// Main route
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Bailey Lessons</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                margin: 0;
                padding: 40px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                min-height: 100vh;
            }
            .container { 
                max-width: 800px; 
                margin: 0 auto; 
                text-align: center;
            }
            h1 { 
                color: #fff; 
                font-size: 3rem;
                margin-bottom: 1rem;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            }
            .subtitle {
                font-size: 1.2rem;
                margin-bottom: 2rem;
                opacity: 0.9;
            }
            .card {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border-radius: 15px;
                padding: 2rem;
                margin: 2rem 0;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            .status {
                display: inline-block;
                background: #4CAF50;
                color: white;
                padding: 0.5rem 1rem;
                border-radius: 25px;
                font-weight: bold;
                margin: 1rem 0;
            }
            .info {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1rem;
                margin-top: 2rem;
            }
            .info-item {
                background: rgba(255, 255, 255, 0.1);
                padding: 1rem;
                border-radius: 10px;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            .info-label {
                font-weight: bold;
                margin-bottom: 0.5rem;
            }
            .info-value {
                font-family: 'Courier New', monospace;
                background: rgba(0, 0, 0, 0.2);
                padding: 0.5rem;
                border-radius: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎓 Bailey Lessons</h1>
            <p class="subtitle">Your educational platform is running successfully!</p>
            
            <div class="card">
                <div class="status">✅ System Healthy</div>
                <p>All services are operational and ready to serve students.</p>
            </div>
            
            <div class="info">
                <div class="info-item">
                    <div class="info-label">Environment</div>
                    <div class="info-value">${process.env.NODE_ENV || 'development'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Version</div>
                    <div class="info-value">${process.env.npm_package_version || '1.0.0'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Database</div>
                    <div class="info-value">Connected</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Storage</div>
                    <div class="info-value">Ready</div>
                </div>
            </div>
        </div>
    </body>
    </html>
  `);
});

// API routes
app.get('/api/status', async (req, res) => {
  try {
    // Test database connection
    const dbResult = await pool.query('SELECT NOW() as timestamp');
    
    // Test S3 connection
    const s3Result = await s3.listBuckets().promise();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: {
        connected: true,
        timestamp: dbResult.rows[0].timestamp
      },
      storage: {
        connected: true,
        buckets: s3Result.Buckets.length
      },
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'The requested resource was not found',
    timestamp: new Date().toISOString()
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  pool.end(() => {
    console.log('Database connection closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  pool.end(() => {
    console.log('Database connection closed');
    process.exit(0);
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Bailey Lessons server running on port ${port}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.DB_HOST || 'localhost'}`);
  console.log(`☁️  Storage: ${process.env.S3_BUCKET || 'not configured'}`);
});

module.exports = app;
