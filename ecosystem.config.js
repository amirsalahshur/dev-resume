module.exports = {
  apps: [
    {
      name: 'amir-portfolio',
      script: 'npm',
      args: 'run serve',
      instances: 'max',
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_file: './logs/pm2-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 4000,
      kill_timeout: 5000,
      listen_timeout: 3000,
      shutdown_with_message: true,
      wait_ready: true,
      health_check_grace_period: 3000,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      instance_var: 'INSTANCE_ID'
    },
    {
      name: 'portfolio-health-check',
      script: './scripts/health-check.js',
      instances: 1,
      exec_mode: 'fork',
      watch: false,
      env: {
        NODE_ENV: 'production',
        HEALTH_CHECK_PORT: 3001,
        MAIN_APP_PORT: 3000
      },
      error_file: './logs/health-check-error.log',
      out_file: './logs/health-check-out.log',
      log_file: './logs/health-check-combined.log',
      time: true,
      autorestart: true,
      max_restarts: 5,
      min_uptime: '10s',
      restart_delay: 2000
    }
  ],

  deploy: {
    production: {
      user: 'portfolio',
      host: ['your-server.com'],
      ref: 'origin/main',
      repo: 'https://github.com/amirsalahshur/dev-resume.git',
      path: '/var/www/portfolio',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': '',
      'ssh_options': 'StrictHostKeyChecking=no'
    }
  }
};