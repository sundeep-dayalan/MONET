import { app } from '@azure/functions';
import express from 'express';
import userRoutes from './routes/user-route';

const expressApp = express();
expressApp.use('/api', userRoutes);

app.http('api', {
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  authLevel: 'anonymous',
  route: 'api/{*restOfPath}',
  handler: async (request, context) => {
    // Proxy Express app through Azure Functions
    return await new Promise((resolve) => {
      expressApp(request as any, {
        status: (code: number) => ({ json: (data: any) => resolve({ status: code, jsonBody: data }) }),
        json: (data: any) => resolve({ jsonBody: data })
      } as any);
    });
  }
});