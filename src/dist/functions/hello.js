"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.hello = void 0;
const functions_1 = require("@azure/functions");
/**
 * A simple HTTP-triggered function that returns a greeting.
 * @param request The incoming HTTP request.
 * @param context The invocation context.
 * @returns An HTTP response.
 */
async function hello(request, context) {
    context.log(`Http function processed request for url "${request.url}"`);
    const name = request.query.get('name') || await request.text() || 'world';
    return { body: `Hello, ${name}! This is a Node.js TypeScript function deployed from GitHub.` };
}
exports.hello = hello;
;
functions_1.app.http('hello', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: hello
});
