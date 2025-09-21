import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';

// Import your existing route handlers
import { errorUser, getUsers } from './controllers/user-controller';

// Convert Express routes to Azure Functions
app.http('users', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'users',
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    // Call your existing controller logic
    const mockRes = {
      status: (code: number) => ({
        json: (data: any) => ({ status: code, jsonBody: data })
      })
    };
    
    const mockReq = {
      // Map Azure Functions request to Express-like request
      query: Object.fromEntries(request.query.entries()),
      body: await request.text()
    };

    try {
      return await getUsers(mockReq as any, mockRes as any, () => {});
    } catch (error) {
      return { status: 500, jsonBody: { error: 'Internal server error' } };
    }
  }
});

app.http('usersError', {
  methods: ['GET'],
  authLevel: 'anonymous', 
  route: 'users/error',
  handler: errorUser as any
});