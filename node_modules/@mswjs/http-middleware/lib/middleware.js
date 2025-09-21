"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMiddleware = createMiddleware;
const node_crypto_1 = __importDefault(require("node:crypto"));
const node_stream_1 = require("node:stream");
const msw_1 = require("msw");
const strict_event_emitter_1 = require("strict-event-emitter");
const emitter = new strict_event_emitter_1.Emitter();
function createMiddleware(...handlers) {
    return (req, res, next) => __awaiter(this, void 0, void 0, function* () {
        var _a;
        const method = req.method || 'GET';
        const serverOrigin = `${req.protocol}://${req.get('host')}`;
        const canRequestHaveBody = method !== 'HEAD' && method !== 'GET';
        const fetchRequest = new Request(
        // Treat all relative URLs as the ones coming from the server.
        new URL(req.url, serverOrigin), {
            method,
            headers: new Headers(req.headers),
            credentials: 'omit',
            // @ts-ignore Internal Undici property.
            duplex: canRequestHaveBody ? 'half' : undefined,
            body: canRequestHaveBody
                ? req.readable
                    ? node_stream_1.Readable.toWeb(req)
                    : ((_a = req.header('content-type')) === null || _a === void 0 ? void 0 : _a.includes('json'))
                        ? JSON.stringify(req.body)
                        : req.body
                : undefined,
        });
        yield (0, msw_1.handleRequest)(fetchRequest, node_crypto_1.default.randomUUID(), handlers, {
            onUnhandledRequest: () => null,
        }, emitter, {
            resolutionContext: {
                /**
                 * @note Resolve relative request handler URLs against
                 * the server's origin (no relative URLs in Node.js).
                 */
                baseUrl: serverOrigin,
            },
            onMockedResponse(mockedResponse) {
                return __awaiter(this, void 0, void 0, function* () {
                    const { status, statusText, headers } = mockedResponse;
                    res.statusCode = status;
                    res.statusMessage = statusText;
                    headers.forEach((value, name) => {
                        /**
                         * @note Use `.appendHeader()` to support multi-value
                         * response headers, like "Set-Cookie".
                         */
                        res.appendHeader(name, value);
                    });
                    if (mockedResponse.body) {
                        const stream = node_stream_1.Readable.fromWeb(mockedResponse.body);
                        stream.pipe(res);
                    }
                    else {
                        res.end();
                    }
                });
            },
            onPassthroughResponse() {
                next();
            },
        }).catch(next);
    });
}
