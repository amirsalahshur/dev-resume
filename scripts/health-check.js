#!/usr/bin/env node

/**
 * Health Check Service for Portfolio Application
 * Provides comprehensive health monitoring and status endpoints
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Configuration
const CONFIG = {
  port: process.env.HEALTH_CHECK_PORT || 3001,
  mainAppPort: process.env.MAIN_APP_PORT || 3000,
  mainAppHost: process.env.MAIN_APP_HOST || 'localhost',
  logLevel: process.env.LOG_LEVEL || 'info',
  checkInterval: parseInt(process.env.HEALTH_CHECK_INTERVAL) || 30000, // 30 seconds
  timeout: parseInt(process.env.HEALTH_CHECK_TIMEOUT) || 5000, // 5 seconds
  criticalThresholds: {
    memoryUsage: 90, // percentage
    cpuUsage: 90,    // percentage
    diskUsage: 95    // percentage
  }
};

// Health status store
let healthStatus = {
  status: 'unknown',
  timestamp: new Date().toISOString(),
  uptime: 0,
  checks: {},
  metrics: {},
  version: require('../package.json').version
};

// Logger utility
class Logger {
  constructor(level = 'info') {
    this.levels = { error: 0, warn: 1, info: 2, debug: 3 };
    this.level = this.levels[level] || 2;
  }

  log(level, message, data = {}) {
    if (this.levels[level] <= this.level) {
      const timestamp = new Date().toISOString();
      const logEntry = {
        timestamp,
        level: level.toUpperCase(),
        message,
        ...data
      };
      console.log(JSON.stringify(logEntry));
    }
  }

  error(message, data) { this.log('error', message, data); }
  warn(message, data) { this.log('warn', message, data); }
  info(message, data) { this.log('info', message, data); }
  debug(message, data) { this.log('debug', message, data); }
}

const logger = new Logger(CONFIG.logLevel);

// Health check utilities
class HealthChecker {
  constructor() {
    this.startTime = Date.now();
  }

  // Check main application health
  async checkMainApp() {
    return new Promise((resolve) => {
      const options = {
        hostname: CONFIG.mainAppHost,
        port: CONFIG.mainAppPort,
        path: '/',
        method: 'GET',
        timeout: CONFIG.timeout
      };

      const req = http.request(options, (res) => {
        const success = res.statusCode >= 200 && res.statusCode < 400;
        resolve({
          name: 'main_app',
          status: success ? 'healthy' : 'unhealthy',
          statusCode: res.statusCode,
          responseTime: Date.now() - startTime
        });
      });

      const startTime = Date.now();

      req.on('error', (error) => {
        resolve({
          name: 'main_app',
          status: 'unhealthy',
          error: error.message,
          responseTime: Date.now() - startTime
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({
          name: 'main_app',
          status: 'unhealthy',
          error: 'Request timeout',
          responseTime: CONFIG.timeout
        });
      });

      req.end();
    });
  }

  // Check filesystem health
  async checkFilesystem() {
    try {
      const distPath = path.join(__dirname, '..', 'dist');
      const indexPath = path.join(distPath, 'index.html');
      
      const distExists = fs.existsSync(distPath);
      const indexExists = fs.existsSync(indexPath);
      
      // Check disk usage
      const stats = fs.statSync('.');
      const { size, free } = await this.getDiskUsage();
      const usagePercent = ((size - free) / size) * 100;
      
      return {
        name: 'filesystem',
        status: distExists && indexExists && usagePercent < CONFIG.criticalThresholds.diskUsage ? 'healthy' : 'unhealthy',
        details: {
          distExists,
          indexExists,
          diskUsagePercent: Math.round(usagePercent * 100) / 100
        }
      };
    } catch (error) {
      return {
        name: 'filesystem',
        status: 'unhealthy',
        error: error.message
      };
    }
  }

  // Get disk usage
  async getDiskUsage() {
    return new Promise((resolve, reject) => {
      const exec = require('child_process').exec;
      exec('df -k .', (error, stdout) => {
        if (error) {
          reject(error);
          return;
        }
        
        const lines = stdout.split('\n');
        const data = lines[1].split(/\s+/);
        const size = parseInt(data[1]) * 1024;
        const used = parseInt(data[2]) * 1024;
        const free = parseInt(data[3]) * 1024;
        
        resolve({ size, used, free });
      });
    });
  }

  // Check system resources
  async checkSystemResources() {
    try {
      const memUsage = process.memoryUsage();
      const systemMem = {
        total: os.totalmem(),
        free: os.freemem()
      };
      
      const memoryUsagePercent = ((systemMem.total - systemMem.free) / systemMem.total) * 100;
      const cpuUsage = await this.getCpuUsage();
      
      const isHealthy = memoryUsagePercent < CONFIG.criticalThresholds.memoryUsage && 
                       cpuUsage < CONFIG.criticalThresholds.cpuUsage;
      
      return {
        name: 'system_resources',
        status: isHealthy ? 'healthy' : 'unhealthy',
        details: {
          memory: {
            processUsage: memUsage,
            systemUsagePercent: Math.round(memoryUsagePercent * 100) / 100,
            systemTotal: systemMem.total,
            systemFree: systemMem.free
          },
          cpu: {
            usagePercent: Math.round(cpuUsage * 100) / 100,
            loadAverage: os.loadavg()
          },
          uptime: {
            process: Math.floor((Date.now() - this.startTime) / 1000),
            system: os.uptime()
          }
        }
      };
    } catch (error) {
      return {
        name: 'system_resources',
        status: 'unhealthy',
        error: error.message
      };
    }
  }

  // Get CPU usage
  async getCpuUsage() {
    return new Promise((resolve) => {
      const startUsage = process.cpuUsage();
      const startTime = Date.now();
      
      setTimeout(() => {
        const currentUsage = process.cpuUsage(startUsage);
        const currentTime = Date.now();
        const cpuPercent = (currentUsage.user + currentUsage.system) / ((currentTime - startTime) * 1000);
        resolve(cpuPercent * 100);
      }, 100);
    });
  }

  // Run all health checks
  async runHealthChecks() {
    const checks = await Promise.all([
      this.checkMainApp(),
      this.checkFilesystem(),
      this.checkSystemResources()
    ]);

    const allHealthy = checks.every(check => check.status === 'healthy');
    const overallStatus = allHealthy ? 'healthy' : 'unhealthy';

    healthStatus = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      uptime: Math.floor((Date.now() - this.startTime) / 1000),
      checks: checks.reduce((acc, check) => {
        acc[check.name] = check;
        return acc;
      }, {}),
      version: require('../package.json').version
    };

    logger.info('Health check completed', { status: overallStatus });
    return healthStatus;
  }
}

// HTTP server for health endpoints
class HealthServer {
  constructor(healthChecker) {
    this.healthChecker = healthChecker;
    this.server = null;
  }

  // Handle health check requests
  async handleRequest(req, res) {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const path = url.pathname;

    // Set common headers
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');

    try {
      switch (path) {
        case '/health':
          await this.handleHealthCheck(req, res);
          break;
        case '/health/live':
          this.handleLivenessCheck(req, res);
          break;
        case '/health/ready':
          await this.handleReadinessCheck(req, res);
          break;
        case '/metrics':
          await this.handleMetrics(req, res);
          break;
        case '/status':
          this.handleStatus(req, res);
          break;
        default:
          res.writeHead(404);
          res.end(JSON.stringify({ error: 'Not found' }));
      }
    } catch (error) {
      logger.error('Error handling request', { path, error: error.message });
      res.writeHead(500);
      res.end(JSON.stringify({ error: 'Internal server error' }));
    }
  }

  // Main health check endpoint
  async handleHealthCheck(req, res) {
    const health = await this.healthChecker.runHealthChecks();
    const statusCode = health.status === 'healthy' ? 200 : 503;
    
    res.writeHead(statusCode);
    res.end(JSON.stringify(health, null, 2));
  }

  // Liveness probe (for Kubernetes)
  handleLivenessCheck(req, res) {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'alive', timestamp: new Date().toISOString() }));
  }

  // Readiness probe (for Kubernetes)
  async handleReadinessCheck(req, res) {
    const mainAppCheck = await this.healthChecker.checkMainApp();
    const isReady = mainAppCheck.status === 'healthy';
    const statusCode = isReady ? 200 : 503;
    
    res.writeHead(statusCode);
    res.end(JSON.stringify({
      status: isReady ? 'ready' : 'not_ready',
      timestamp: new Date().toISOString(),
      mainApp: mainAppCheck
    }));
  }

  // Prometheus-style metrics endpoint
  async handleMetrics(req, res) {
    const health = await this.healthChecker.runHealthChecks();
    
    res.setHeader('Content-Type', 'text/plain');
    res.writeHead(200);
    
    let metrics = `# HELP portfolio_health_status Overall health status (1 = healthy, 0 = unhealthy)\n`;
    metrics += `# TYPE portfolio_health_status gauge\n`;
    metrics += `portfolio_health_status{service="portfolio"} ${health.status === 'healthy' ? 1 : 0}\n\n`;
    
    metrics += `# HELP portfolio_uptime_seconds Service uptime in seconds\n`;
    metrics += `# TYPE portfolio_uptime_seconds counter\n`;
    metrics += `portfolio_uptime_seconds{service="portfolio"} ${health.uptime}\n\n`;
    
    // Add individual check metrics
    for (const [name, check] of Object.entries(health.checks)) {
      metrics += `# HELP portfolio_check_${name}_status Health check status (1 = healthy, 0 = unhealthy)\n`;
      metrics += `# TYPE portfolio_check_${name}_status gauge\n`;
      metrics += `portfolio_check_${name}_status{service="portfolio",check="${name}"} ${check.status === 'healthy' ? 1 : 0}\n\n`;
    }
    
    res.end(metrics);
  }

  // Simple status endpoint
  handleStatus(req, res) {
    res.writeHead(200);
    res.end(JSON.stringify({
      service: 'portfolio-health-check',
      status: 'running',
      timestamp: new Date().toISOString(),
      version: require('../package.json').version
    }));
  }

  // Start the server
  start() {
    this.server = http.createServer((req, res) => this.handleRequest(req, res));
    
    this.server.listen(CONFIG.port, () => {
      logger.info(`Health check server started`, { port: CONFIG.port });
    });

    // Graceful shutdown
    process.on('SIGTERM', () => this.shutdown());
    process.on('SIGINT', () => this.shutdown());
  }

  // Shutdown the server
  shutdown() {
    logger.info('Shutting down health check server');
    if (this.server) {
      this.server.close(() => {
        logger.info('Health check server closed');
        process.exit(0);
      });
    }
  }
}

// Main application
async function main() {
  logger.info('Starting health check service', CONFIG);
  
  const healthChecker = new HealthChecker();
  const healthServer = new HealthServer(healthChecker);
  
  // Start the server
  healthServer.start();
  
  // Run periodic health checks
  setInterval(async () => {
    try {
      await healthChecker.runHealthChecks();
    } catch (error) {
      logger.error('Periodic health check failed', { error: error.message });
    }
  }, CONFIG.checkInterval);
  
  // Initial health check
  try {
    await healthChecker.runHealthChecks();
    logger.info('Initial health check completed');
  } catch (error) {
    logger.error('Initial health check failed', { error: error.message });
  }
}

// Start the application
if (require.main === module) {
  main().catch((error) => {
    logger.error('Failed to start health check service', { error: error.message });
    process.exit(1);
  });
}

module.exports = { HealthChecker, HealthServer };