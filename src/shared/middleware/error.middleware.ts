import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/app-error';
import { logger } from '../utils/logger';
import { env } from '../../config/env';

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const isAppError = err instanceof AppError;
  const statusCode = isAppError ? err.statusCode : 500;
  const errorCode = isAppError ? err.code : 'INTERNAL_SERVER_ERROR';
  const requestId = req.id || (req.headers['x-request-id'] as string) || 'unknown';

  // In production, mask unexpected internal server error messages
  const message = (isAppError || env.NODE_ENV !== 'production')
    ? err.message
    : 'An unexpected internal server error occurred.';

  const details = isAppError
    ? err.details
    : (env.NODE_ENV !== 'production' ? { stack: err.stack } : undefined);

  logger.error(err.message, {
    errorCode,
    statusCode,
    requestId,
    path: req.originalUrl,
    method: req.method,
    stack: err.stack,
  });

  res.status(statusCode).json({
    success: false,
    error: {
      code: errorCode,
      message,
      ...(details !== undefined ? { details } : {}),
    },
    meta: {
      timestamp: new Date().toISOString(),
      requestId,
    },
  });
}

