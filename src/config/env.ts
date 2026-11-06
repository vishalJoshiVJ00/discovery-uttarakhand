import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

export const databaseUrlSchema = z
  .string()
  .min(1, 'DATABASE_URL is required')
  .superRefine((val, ctx) => {
    let parsedUrl: URL;
    try {
      parsedUrl = new URL(val);
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'DATABASE_URL is not a valid URL format',
      });
      return;
    }

    if (parsedUrl.protocol !== 'postgresql:' && parsedUrl.protocol !== 'postgres:') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "DATABASE_URL protocol must be 'postgresql:' or 'postgres:'",
      });
    }

    if (!parsedUrl.hostname || parsedUrl.hostname.trim().length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'DATABASE_URL must include a valid hostname',
      });
    }

    const dbName = parsedUrl.pathname.replace(/^\//, '').trim();
    if (!dbName) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'DATABASE_URL must include a valid database name',
      });
    }
  });

export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().default(5000),
  API_PREFIX: z.string().default('/api/v1'),
  CORS_ORIGIN: z.string().default('http://localhost:5173'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  DATABASE_URL: databaseUrlSchema,
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment configuration:');
  console.error(JSON.stringify(parsed.error.format(), null, 2));
  process.exit(1);
}

export const env = parsed.data;
