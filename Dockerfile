# ─────────────────────────────────────────────────────────
# Stage 1: Build Flutter Web
# ─────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Allow running Flutter as root inside Docker
ENV FLUTTER_ALLOW_ROOT=true

# Copy project files
COPY . .

# Enable web platform and fetch dependencies
RUN flutter config --enable-web
RUN flutter pub get

# Generate web platform bootstrap files for the current Flutter version,
# then restore our custom web/index.html with AlterVPN branding.
RUN cp web/index.html /tmp/custom_index.html \
    && flutter create --platforms=web --project-name alter_vpn . \
    && cp /tmp/custom_index.html web/index.html

# Build release web app (CanvasKit is the default renderer in Flutter 3.22+)
RUN flutter build web --release

# ─────────────────────────────────────────────────────────
# Stage 2: Serve with nginx (alpine — minimal image)
# ─────────────────────────────────────────────────────────
FROM nginx:alpine

# Copy built static files
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config template (uses $PORT injected by Railway)
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Railway injects PORT at runtime; default to 8080
ENV PORT=8080

# Limit envsubst substitution to PORT only so nginx variables
# ($uri, $host, etc.) are not mistakenly replaced by the template processor.
ENV NGINX_ENVSUBST_VARS='PORT'

EXPOSE 8080
