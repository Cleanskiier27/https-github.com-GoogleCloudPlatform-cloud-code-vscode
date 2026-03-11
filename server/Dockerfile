FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --production
COPY . .

FROM node:18-alpine
WORKDIR /app
COPY --from=build /app .
LABEL reference.trouble_shooter="TS-20251217-143235-e2d2"
EXPOSE 3000
CMD ["node","server.js"]
