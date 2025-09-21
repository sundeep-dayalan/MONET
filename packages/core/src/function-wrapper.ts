import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import * as fs from 'fs';
import * as path from 'path';

// Simple function that serves both API and static files
app.http('app', {
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  authLevel: 'anonymous',
  route: '{*segments}',
  handler: async (request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> => {
    try {
      const url = new URL(request.url);
      const pathname = url.pathname;
      
      context.log(`Request: ${request.method} ${pathname}`);
      
      // Handle CORS preflight
      if (request.method === 'OPTIONS') {
        return {
          status: 200,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
          }
        };
      }
      
      // API Routes
      if (pathname.startsWith('/api/')) {
        return await handleApiRequest(pathname, request, context);
      }
      
      // Static file serving (frontend)
      return await handleStaticRequest(pathname, context);
      
    } catch (error) {
      context.error('Error in function:', error);
      return {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        jsonBody: {
          success: false,
          message: 'Internal server error',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      };
    }
  }
});

async function handleApiRequest(pathname: string, request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const corsHeaders = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  };
  
  if (pathname === '/api/health') {
    return {
      status: 200,
      headers: corsHeaders,
      jsonBody: {
        success: true,
        message: 'MONET API is healthy',
        timestamp: new Date().toISOString(),
        environment: 'Azure Functions'
      }
    };
  }
  
  if (pathname === '/api' || pathname === '/api/') {
    return {
      status: 200,
      headers: corsHeaders,
      jsonBody: {
        success: true,
        message: 'MONET API',
        version: '1.0.0',
        endpoints: [
          'GET /api/health',
          'GET /api/users',
          'GET /api/users/error'
        ]
      }
    };
  }
  
  if (pathname === '/api/users') {
    return {
      status: 200,
      headers: corsHeaders,
      jsonBody: {
        success: true,
        data: [
          { name: "John Doe" },
          { name: "Jane Doe" }
        ],
        message: "Users retrieved successfully"
      }
    };
  }
  
  if (pathname === '/api/users/error') {
    return {
      status: 500,
      headers: corsHeaders,
      jsonBody: {
        success: false,
        message: "This is a test error endpoint",
        data: {}
      }
    };
  }
  
  // API 404
  return {
    status: 404,
    headers: corsHeaders,
    jsonBody: {
      success: false,
      message: `API route ${pathname} not found`,
      availableRoutes: [
        'GET /api/health',
        'GET /api',
        'GET /api/users',
        'GET /api/users/error'
      ]
    }
  };
}

async function handleStaticRequest(pathname: string, context: InvocationContext): Promise<HttpResponseInit> {
  try {
    // Serve index.html for SPA routes
    if (pathname === '/' || pathname === '' || !pathname.includes('.')) {
      const indexPath = path.join(process.cwd(), 'wwwroot', 'frontend', 'index.html');
      if (fs.existsSync(indexPath)) {
        const content = fs.readFileSync(indexPath, 'utf8');
        return {
          status: 200,
          headers: { 'Content-Type': 'text/html' },
          body: content
        };
      }
    }
    
    // Serve static files (CSS, JS, images, etc.)
    const filePath = path.join(process.cwd(), 'wwwroot', 'frontend', pathname);
    if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
      const content = fs.readFileSync(filePath);
      const contentType = getContentType(pathname);
      
      return {
        status: 200,
        headers: { 'Content-Type': contentType },
        body: content
      };
    }
    
    // Fallback to index.html for SPA routing
    const indexPath = path.join(process.cwd(), 'wwwroot', 'frontend', 'index.html');
    if (fs.existsSync(indexPath)) {
      const content = fs.readFileSync(indexPath, 'utf8');
      return {
        status: 200,
        headers: { 'Content-Type': 'text/html' },
        body: content
      };
    }
    
    // 404 for static files
    return {
      status: 404,
      headers: { 'Content-Type': 'text/html' },
      body: '<h1>404 - Page Not Found</h1>'
    };
    
  } catch (error) {
    context.error('Error serving static file:', error);
    return {
      status: 500,
      headers: { 'Content-Type': 'text/html' },
      body: '<h1>500 - Internal Server Error</h1>'
    };
  }
}

function getContentType(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  const contentTypes: { [key: string]: string } = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf',
    '.eot': 'application/vnd.ms-fontobject'
  };
  return contentTypes[ext] || 'application/octet-stream';
}