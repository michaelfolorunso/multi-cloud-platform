# stage 1 — node just for building, we dont need it in the final image
FROM node:20-alpine AS builder

WORKDIR /app

# dependencies first, code changes wont blow away the cache this way
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# outputs static files to /app/build, thats all we actually need
RUN npm run build

# stage 2 — nginx is tiny and purpose built for this, node would be overkill
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]