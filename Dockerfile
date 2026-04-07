# ── Stage 1: Build Flutter web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Railway passes these as Docker build args from the service's environment vars
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

WORKDIR /app

# Cache pub dependencies (invalidated only when pubspec changes)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and build — secrets baked into main.dart.js at compile time
COPY . .
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# ── Stage 2: Serve with nginx ──────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
