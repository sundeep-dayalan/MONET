"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createServer = createServer;
const express_1 = __importDefault(require("express"));
const middleware_1 = require("./middleware");
function createServer(...handlers) {
    const app = (0, express_1.default)();
    app.use((0, middleware_1.createMiddleware)(...handlers));
    app.use((_req, res) => {
        res.status(404).json({
            error: 'Mock not found',
        });
    });
    return app;
}
