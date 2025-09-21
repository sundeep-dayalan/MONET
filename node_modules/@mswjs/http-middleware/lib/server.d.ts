import express from 'express';
import { RequestHandler } from 'msw';
export declare function createServer(...handlers: Array<RequestHandler>): express.Express;
