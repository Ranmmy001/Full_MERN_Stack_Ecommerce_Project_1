# Stage 1: Build stage
FROM node:18-alpine AS build  
WORKDIR /app

COPY package*.json ./

RUN npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-retries 5 \
    && npm ci

COPY . .

# Accept build arguments from docker-compose.yml
ARG REACT_APP_API_URL
ARG VITE_API_URL

# Expose build arguments to Node environment during npm run build
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV VITE_API_URL=$VITE_API_URL

ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm run build

# Stage 2: Production Nginx stage
FROM nginx:alpine

# Copy static assets to Nginx public directory
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
