import app from './app';
import { env } from './config/env';
import { logger } from './shared/utils/logger';
import { prisma } from './shared/database/prisma';

const server = app.listen(env.PORT, () => {
  logger.info(`Discovery Uttarakhand API server listening on port ${env.PORT}`, {
    port: env.PORT,
    environment: env.NODE_ENV,
    apiPrefix: env.API_PREFIX,
  });
});

let isShuttingDown = false;

function handleGracefulShutdown(signal: string): void {
  if (isShuttingDown) {
    return;
  }
  isShuttingDown = true;

  logger.info(`Received ${signal}. Commencing graceful server shutdown...`);

  server.close(async (err) => {
    if (err) {
      logger.error('Error encountered while closing HTTP server', { error: err.message });
      process.exit(1);
    }

    try {
      await prisma.$disconnect();
      logger.info('Database connection closed cleanly.');
    } catch (dbErr) {
      const errorMsg = dbErr instanceof Error ? dbErr.message : 'Unknown database disconnect error';
      logger.error('Error encountered while disconnecting database client', { error: errorMsg });
    }

    logger.info('HTTP server closed successfully. Process terminating cleanly.');
    process.exit(0);
  });

  // Force close if server takes longer than 10 seconds to shut down
  setTimeout(() => {
    logger.error('Server shutdown timed out. Forcing process termination.');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => handleGracefulShutdown('SIGTERM'));
process.on('SIGINT', () => handleGracefulShutdown('SIGINT'));
