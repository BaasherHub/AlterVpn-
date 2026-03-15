# ─────────────────────────────────────────────────────────
# Stage 1: Build Flutter Web
# ─────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

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

# Build release web app with CanvasKit renderer for best fidelity
RUN flutter build web --release --web-renderer canvaskit

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

EXPOSE 8080
