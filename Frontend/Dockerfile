# Stage 1: Build the React application, by compiling raw React source code into optimized static files.
FROM node:18-alpine AS build  
WORKDIR /app

COPY package*.json ./

# Configure npm timeouts and install dependencies
RUN npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-retries 5 \
    && npm ci

# Copies the rest of your local React project files into the container's /app directory.
COPY . .

# Accept build arguments from docker-compose.yml
ARG REACT_APP_API_URL
ARG VITE_API_URL

# Expose build arguments to Node environment during npm run build
ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV VITE_API_URL=$VITE_API_URL

# Increase Node memory limit for the React build
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm run build

# Stage 2: Serve compiled assets using lightweight Nginx
FROM nginx:alpine

# Copy custom build output to Nginx default public directory
# Note: Change /app/build to /app/dist if using Vite
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]