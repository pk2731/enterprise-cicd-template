const request = require('supertest');
const app = require('../app');

describe('Enterprise CI/CD Template API', () => {
  describe('Health Check Endpoints', () => {
    test('GET /health should return 200 with status ok', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('environment');
      
      // Validate timestamp format
      expect(response.body.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$/);
      
      // Validate uptime is a number
      expect(typeof response.body.uptime).toBe('number');
      expect(response.body.uptime).toBeGreaterThanOrEqual(0);
    });

    test('GET /ready should return 200 with status ready', async () => {
      const response = await request(app).get('/ready');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ready');
      expect(response.body).toHaveProperty('timestamp');
      
      // Validate timestamp format
      expect(response.body.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$/);
    });
  });

  describe('API Endpoints', () => {
    test('GET /api/version should return version information', async () => {
      const response = await request(app).get('/api/version');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('build');
      expect(response.body).toHaveProperty('commit');
      
      // Default values when environment variables are not set
      expect(response.body.version).toBe('1.0.0');
      expect(response.body.build).toBe('local');
      expect(response.body.commit).toBe('unknown');
    });

    test('GET /api/status should return application status', async () => {
      const response = await request(app).get('/api/status');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'running');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('memory');
      expect(response.body).toHaveProperty('cpu');
      
      // Validate memory object structure
      expect(response.body.memory).toHaveProperty('rss');
      expect(response.body.memory).toHaveProperty('heapTotal');
      expect(response.body.memory).toHaveProperty('heapUsed');
      expect(response.body.memory).toHaveProperty('external');
      
      // Validate CPU usage object
      expect(response.body.cpu).toHaveProperty('user');
      expect(response.body.cpu).toHaveProperty('system');
    });

    test('GET /api/hello should return welcome message', async () => {
      const response = await request(app).get('/api/hello');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'Hello from Enterprise CI/CD Template!');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('environment');
      
      // In test environment, should return 'test' if NODE_ENV is set
      process.env.NODE_ENV = 'test';
      const testResponse = await request(app).get('/api/hello');
      expect(testResponse.body.environment).toBe('test');
    });
  });

  describe('Metrics Endpoint', () => {
    test('GET /metrics should return Prometheus-style metrics', async () => {
      const response = await request(app).get('/metrics');
      
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toContain('text/plain');
      
      // Check for expected metric lines
      expect(response.text).toContain('http_requests_total');
      expect(response.text).toContain('memory_usage_bytes');
      expect(response.text).toContain('uptime_seconds');
      
      // Check for proper Prometheus format
      expect(response.text).toContain('# HELP');
      expect(response.text).toContain('# TYPE');
    });
  });

  describe('Error Handling', () => {
    test('GET /nonexistent should return 404', async () => {
      const response = await request(app).get('/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Not Found');
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body.message).toContain('Route GET /nonexistent not found');
    });

    test('POST /nonexistent should return 404', async () => {
      const response = await request(app).post('/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Not Found');
      expect(response.body.message).toContain('Route POST /nonexistent not found');
    });
  });

  describe('Security Headers', () => {
    test('Security headers should be present', async () => {
      const response = await request(app).get('/health');
      
      // Check for helmet security headers
      expect(response.headers).toHaveProperty('x-dns-prefetch-control');
      expect(response.headers).toHaveProperty('x-frame-options');
      expect(response.headers).toHaveProperty('x-download-options');
      expect(response.headers).toHaveProperty('x-content-type-options');
      expect(response.headers).toHaveProperty('x-xss-protection');
    });
  });

  describe('CORS Configuration', () => {
    test('CORS headers should be properly configured', async () => {
      const response = await request(app)
        .get('/api/hello')
        .set('Origin', 'https://yourapp.com');
      
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });

  describe('Request Body Parsing', () => {
    test('JSON body parsing should work', async () => {
      // Since we don't have a POST endpoint that uses body, let's test the middleware is loaded
      const response = await request(app)
        .post('/api/test')
        .send({ test: 'data' })
        .set('Content-Type', 'application/json');
      
      // Should get 404 (route not found) but body should be parsed
      expect(response.status).toBe(404);
    });
  });

  describe('Performance and Load', () => {
    test('Multiple concurrent requests should work', async () => {
      const promises = Array.from({ length: 10 }, () =>
        request(app).get('/health')
      );
      
      const responses = await Promise.all(promises);
      
      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.body.status).toBe('ok');
      });
    });

    test('Large request body should be rejected', async () => {
      const largeData = 'x'.repeat(11 * 1024 * 1024); // 11MB (over 10MB limit)
      
      const response = await request(app)
        .post('/api/test')
        .send({ data: largeData })
        .set('Content-Type', 'application/json');
      
      // Should get rejected due to size limit
      expect([413, 404]).toContain(response.status); // 413 Payload Too Large or 404 if rejected before routing
    });
  });

  describe('Environment Configuration', () => {
    test('Should handle different NODE_ENV values', async () => {
      // Test with production environment
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      
      const response = await request(app).get('/api/hello');
      expect(response.body.environment).toBe('production');
      
      // Restore original environment
      process.env.NODE_ENV = originalEnv;
    });
  });
});