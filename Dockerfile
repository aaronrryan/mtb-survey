FROM nginx:alpine

ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}

# Copy the static files
COPY index.html /tmp/
RUN envsubst '${APP_VERSION}' < /tmp/index.html > /usr/share/nginx/html/index.html

# Copy custom nginx config if needed
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 