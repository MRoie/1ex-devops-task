FROM oven/bun:1.0 AS build
WORKDIR /app
COPY . .
RUN bun install && bun run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
