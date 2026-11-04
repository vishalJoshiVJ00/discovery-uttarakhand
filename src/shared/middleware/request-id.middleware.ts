import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

declare global {
  namespace Express {
    interface Request {
      id?: string;
    }
  }
}

const REQUEST_ID_REGEX = /^[A-Za-z0-9._:-]{1,64}$/;

export function requestIdMiddleware(req: Request, res: Response, next: NextFunction): void {
  const rawHeader = req.headers['x-request-id'];
  let requestId: string | undefined;

  if (typeof rawHeader === 'string') {
    const trimmed = rawHeader.trim();
    if (REQUEST_ID_REGEX.test(trimmed)) {
      requestId = trimmed;
    }
  }

  if (!requestId) {
    requestId = `req_${uuidv4().replace(/-/g, '').slice(0, 12)}`;
  }

  req.id = requestId;
  res.setHeader('X-Request-Id', requestId);
  next();
}

