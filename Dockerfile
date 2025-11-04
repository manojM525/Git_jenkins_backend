# Use Node LTS base image
FROM node:18

# Set work directory
WORKDIR /app

# Copy package.json first for better caching
COPY package.json ./

# Install dependencies
RUN npm install

# Copy rest of code
COPY . .

# Expose port
EXPOSE 5000

# Run app
CMD ["node", "server.js"]


##test purpose only