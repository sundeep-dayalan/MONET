import type { RequestHandler as ExpressMiddleware } from 'express';
import type { RequestHandler } from 'msw';
export declare function createMiddleware(...handlers: Array<RequestHandler>): ExpressMiddleware;
