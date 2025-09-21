import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import hpp from 'hpp';

// Import your existing routes
import userRoutes from './routes/user-route';

// Create Express app (reusing your app.ts logic but without listen)
const expressApp = express();

// Body parser
expressApp.use(express.json());

// Enable CORS for Azure Functions
expressApp.use(cors({
  origin: '*',
  credentials: false
}));

// Security Headers (simplified for Azure Functions)
expressApp.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for Azure Functions
}));

// Secure against param pollutions
expressApp.use(hpp());

// Setup routing with /api prefix to match Azure Functions convention
expressApp.use('/api/users', userRoutes);

// Health check endpoint
expressApp.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'MONET API is healthy',
    timestamp: new Date().toISOString(),
    environment: 'Azure Functions'
  });
});

// Root endpoint
expressApp.get('/api', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'MONET API',
    version: '1.0.0',
    endpoints: [
      'GET /api/health',
      'GET /api/users',
      'GET /api/users/error'
    ]
  });
});

// Catch-all for debugging
expressApp.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} not found`,
    availableRoutes: [
      'GET /api/health',
      'GET /api/users',
      'GET /api/users/error'
    ]
  });
});

// Azure Function that wraps the entire Express app
app.http('expressApp', {
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  authLevel: 'anonymous',
  route: '{*segments}', // Catch all routes
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    return new Promise(async (resolve) => {
      try {
        // Parse request body for POST/PUT/PATCH requests
        let body = {};
        if (['POST', 'PUT', 'PATCH'].includes(request.method)) {
          try {
            const bodyText = await request.text();
            body = bodyText ? JSON.parse(bodyText) : {};
          } catch (error) {
            body = {};
          }
        }

        // Create Express-compatible request object
        const mockRequest = {
          method: request.method,
          url: request.url,
          path: new URL(request.url).pathname,
          query: Object.fromEntries(request.query.entries()),
          params: {},
          headers: Object.fromEntries(request.headers.entries()),
          body: body,
          get(headerName: string) {
            return this.headers[headerName.toLowerCase()];
          }
        };

        // Create Express-compatible response object
        const mockResponse = {
          statusCode: 200,
          headers: {} as Record<string, string>,
          body: '',

          status(code: number) {
            this.statusCode = code;
            return this;
          },

          json(data: any) {
            this.headers['Content-Type'] = 'application/json';
            this.body = JSON.stringify(data);
            this.end();
            return this;
          },

          send(data: any) {
            if (typeof data === 'object') {
              this.headers['Content-Type'] = 'application/json';
              this.body = JSON.stringify(data);
            } else {
              this.body = String(data);
            }
            this.end();
            return this;
          },

          setHeader(name: string, value: string) {
            this.headers[name] = value;
            return this;
          },

          set(name: string, value: string) {
            this.headers[name] = value;
            return this;
          },

          end() {
            // Add CORS headers
            this.headers['Access-Control-Allow-Origin'] = '*';
            this.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
            this.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';

            resolve({
              status: this.statusCode,
              headers: this.headers,
              body: this.body
            });
          }
        };

        // Handle the request with Express
        expressApp(mockRequest as any, mockResponse as any);

      } catch (error) {
        context.error('Error in Express wrapper:', error);
        resolve({
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          },
          body: JSON.stringify({
            success: false,
            message: 'Internal server error',
            error: process.env.NODE_ENV === 'development' ? error : undefined
          })
        });
      }
    });
  }
});