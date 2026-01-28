# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter build web --release

# Serve stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080
RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf
