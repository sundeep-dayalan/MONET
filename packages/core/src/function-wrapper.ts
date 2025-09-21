import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';

app.http('users', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'users',
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    return {
      status: 200,
      jsonBody: {
        success: true,
        data: [{ name: "John Doe" }, { name: "Jane Doe" }],
        message: "Success from Azure Functions!"
      }
    };
  }
});