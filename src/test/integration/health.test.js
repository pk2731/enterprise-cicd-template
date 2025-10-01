const request = require('supertest');
const app = require('../../app');

describe('Integration Tests - Health & Monitoring', () => {
  describe('Health Check Integration', () => {
    test('Health check should work in sequence with other endpoints', async () => {
      // Test sequence: health -> version -> status -> metrics
      const healthResponse = await request(app).get('/health');
      expect(healthResponse.status).toBe(200);
      expect(healthResponse.body.status).toBe('ok');

      const versionResponse = await request(app).get('/api/version');
      expect(versionResponse.status).toBe(200);
      expect(versionResponse.body).toHaveProperty('version');

      const statusResponse = await request(app).get('/api/status');
      expect(statusResponse.status).toBe(200);
      expect(statusResponse.body.status).toBe('running');

      const metricsResponse = await request(app).get('/metrics');
      expect(metricsResponse.status).toBe(200);
      expect(metricsResponse.headers['content-type']).toContain('text/plain');
    });

    test('All health-related endpoints should respond within acceptable time', async () => {
      const startTime = Date.now();
      
      const responses = await Promise.all([
        request(app).get('/health'),
        request(app).get('/ready'),
        request(app).get('/api/status'),
        request(app).get('/metrics')
      ]);

      const endTime = Date.now();
      const totalTime = endTime - startTime;

      // All requests should complete within 2 seconds
      expect(totalTime).toBeLessThan(2000);

      // All responses should be successful
      responses.forEach(response => {
        expect(response.status).toBe(200);
      });
    });
  });

  describe('API Integration', () => {
    test('API endpoints should work together coherently', async () => {
      // Test API workflow
      const helloResponse = await request(app).get('/api/hello');
      expect(helloResponse.status).toBe(200);
      expect(helloResponse.body.message).toContain('Enterprise CI/CD Template');

      // Check that timestamps are consistent (within reasonable time window)
      const version1Response = await request(app).get('/api/version');
      const version2Response = await request(app).get('/api/version');
      
      expect(version1Response.status).toBe(200);
      expect(version2Response.status).toBe(200);
      
      // Both should return the same version info
      expect(version1Response.body.version).toBe(version2Response.body.version);
      expect(version1Response.body.build).toBe(version2Response.body.build);
    });
  });

  describe('Error Handling Integration', () => {
    test('Error responses should be consistent across different invalid requests', async () => {
      const invalidEndpoints = [
        '/api/nonexistent',
        '/invalid/path',
        '/api/missing',
        '/health/invalid'
      ];

      const responses = await Promise.all(
        invalidEndpoints.map(endpoint => request(app).get(endpoint))
      );

      responses.forEach((response, index) => {
        expect(response.status).toBe(404);
        expect(response.body).toHaveProperty('error', 'Not Found');
        expect(response.body).toHaveProperty('message');
        expect(response.body).toHaveProperty('timestamp');
        expect(response.body.message).toContain(`Route GET ${invalidEndpoints[index]} not found`);
      });
    });
  });

  describe('Load Testing Integration', () => {
    test('Application should handle sustained load', async () => {
      const concurrentRequests = 20;
      const requestsPerBatch = 5;
      const batches = concurrentRequests / requestsPerBatch;

      for (let batch = 0; batch < batches; batch++) {
        const batchRequests = Array.from({ length: requestsPerBatch }, () =>
          request(app).get('/health')
        );

        const batchResponses = await Promise.all(batchRequests);

        batchResponses.forEach(response => {
          expect(response.status).toBe(200);
          expect(response.body.status).toBe('ok');
        });

        // Small delay between batches
        await new Promise(resolve => setTimeout(resolve, 10));
      }
    });
  });

  describe('Security Integration', () => {
    test('Security headers should be consistently applied across all endpoints', async () => {
      const endpoints = [
        '/health',
        '/ready',
        '/api/version',
        '/api/status',
        '/api/hello',
        '/metrics'
      ];

      const responses = await Promise.all(
        endpoints.map(endpoint => request(app).get(endpoint))
      );

      responses.forEach(response => {
        // All should return 200
        expect(response.status).toBe(200);
        
        // Check for consistent security headers (from helmet)
        expect(response.headers).toHaveProperty('x-frame-options');
        expect(response.headers).toHaveProperty('x-content-type-options');
        expect(response.headers).toHaveProperty('x-xss-protection');
      });
    });

    test('CORS should be properly configured for cross-origin requests', async () => {
      const response = await request(app)
        .get('/api/hello')
        .set('Origin', 'https://yourapp.com');

      expect(response.status).toBe(200);
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });

  describe('Environment Configuration Integration', () => {
    test('Application should behave consistently across environment changes', async () => {
      const originalEnv = process.env.NODE_ENV;

      // Test different environments
      const environments = ['development', 'staging', 'production', 'test'];

      for (const env of environments) {
        process.env.NODE_ENV = env;

        const response = await request(app).get('/api/hello');
        expect(response.status).toBe(200);
        expect(response.body.environment).toBe(env);
      }

      // Restore original environment
      process.env.NODE_ENV = originalEnv;
    });
  });
});