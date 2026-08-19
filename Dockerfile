FROM node:alpine

WORKDIR /usr/src/app

# Copy the repository files
COPY . .

# Hardening Requirement: Switch execution context to non-root user
USER node

# Default command
CMD ["node", "-e", "console.log('Cargo Ship Active')"]