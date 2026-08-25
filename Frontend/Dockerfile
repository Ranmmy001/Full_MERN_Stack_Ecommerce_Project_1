# Stage 1: Build the React application, by compiling raw React source code into optimized static files.
FROM node:18-alpine AS build  
##Pulls a lightweight Linux image that has Node.js v18 pre-installed and names this temporary build stage

##Creates and sets /app as the main working directory inside the container.
WORKDIR /app

##Copies package.json and package-lock.json from your local machine into /app/ inside the container.
COPY package*.json ./

# Configure npm timeouts and install dependencies
RUN npm config set fetch-retry-maxtimeout 600000 \
    && npm config set fetch-retries 5 \
    && npm ci
    #Runs npm clean-install inside the container.


#Copies the rest of your local React project files into the container's /app directory.
COPY . .

# Increase Node memory limit for the React build
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm run build

# Stage 2: Serve compiled assets using lightweight Nginx
FROM nginx:alpine

# Copy custom build output to Nginx default public directory
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

