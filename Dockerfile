FROM node:20-alpine

# su-exec: drop from root to node after fixing volume ownership in entrypoint
RUN apk add --no-cache su-exec

WORKDIR /app

# Install production dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

# Persistent state (keypair, device identity, tracked payments, logs, ...)
# lives in /data — mount it as a volume in Coolify.
RUN mkdir -p /data && chown -R node:node /data /app

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT}/health || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]
