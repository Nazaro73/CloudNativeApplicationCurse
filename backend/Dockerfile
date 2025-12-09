# Build stage
FROM node:18-alpine AS build

WORKDIR /app

RUN apk add --no-cache jq openssl

COPY package*.json ./
# Remove "type": "module" to use CommonJS
RUN jq 'del(.type)' package.json > package.tmp.json && mv package.tmp.json package.json
RUN npm install --omit=dev

COPY src ./src
COPY prisma ./prisma
RUN npx prisma generate

# Production stage
FROM node:18-alpine AS production

RUN apk add --no-cache openssl

WORKDIR /app

COPY --from=build /app/src ./src
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
COPY --from=build /app/prisma ./prisma

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "src/index.js"]
