import winston from 'winston';
import { env } from '../../config/env';

// Redact sensitive patterns from log entries
const redactSensitiveData = winston.format((info) => {
  const sensitiveKeys = ['password', 'otp', 'token', 'authorization', 'cookie', 'secret', 'key'];

  const maskObject = (obj: Record<string, unknown>): Record<string, unknown> => {
    const masked: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj)) {
      if (sensitiveKeys.some((k) => key.toLowerCase().includes(k))) {
        masked[key] = '[REDACTED]';
      } else if (value && typeof value === 'object' && !Array.isArray(value)) {
        masked[key] = maskObject(value as Record<string, unknown>);
      } else {
        masked[key] = value;
      }
    }
    return masked;
  };

  if (typeof info === 'object' && info !== null) {
    return maskObject(info as Record<string, unknown>) as winston.Logform.TransformableInfo;
  }
  return info;
});

export const logger = winston.createLogger({
  level: env.LOG_LEVEL,
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
    winston.format.errors({ stack: true }),
    redactSensitiveData(),
    winston.format.json()
  ),
  defaultMeta: { service: 'discovery-uttarakhand-api' },
  transports: [
    new winston.transports.Console()
  ],
});

