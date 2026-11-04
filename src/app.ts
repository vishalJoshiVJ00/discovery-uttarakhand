import express, { Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { env } from './config/env';
import { requestIdMiddleware } from './shared/middleware/request-id.middleware';
import { errorHandler } from './shared/middleware/error.middleware';
import { NotFoundError } from './shared/errors/app-error';

const app = express();

// Security Headers & Cross-Origin Resource Sharing
app.use(helmet());
const allowedOrigins = env.CORS_ORIGIN.split(',').map((origin) => origin.trim());
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (e.g. mobile apps, curl, server-to-server) or whitelisted origins
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error(`CORS blocked for origin: ${origin}`));
      }
    },
    credentials: true,
  })
);

// Standard JSON Body Parsing & Request Tracing
app.use(express.json());
app.use(requestIdMiddleware);

// Liveness Health Check Endpoint
app.get(`${env.API_PREFIX}/health`, (req: Request, res: Response) => {
  const now = new Date().toISOString();
  const requestId = req.id || 'unknown';

  res.status(200).json({
    success: true,
    data: {
      status: 'healthy',
      uptime: process.uptime(),
      timestamp: now,
    },
    meta: {
      timestamp: now,
      requestId,
    },
  });
});

// 404 Handler for Unmatched Endpoints
app.use((_req: Request, _res: Response, next: NextFunction) => {
  next(new NotFoundError('Requested API endpoint does not exist.'));
});

// Centralized Application Error Handler
app.use(errorHandler);

export default app;

