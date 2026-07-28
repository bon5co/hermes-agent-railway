FROM nousresearch/hermes-agent:v2026.7.20

# Railway wrapper around the official Nous Research image.
#
# Everything the platform needs is baked in here rather than left as template
# variables, because Railway's `templateGenerate` drops literal defaults: a
# variable carrying a literal value publishes as "required, no default" and the
# deploy form asks the user to type a value the image already knows. Baking them
# leaves exactly one field on the form (the dashboard password), pre-filled.
ENV HERMES_DASHBOARD=1 \
    HERMES_DASHBOARD_HOST=0.0.0.0 \
    HERMES_DASHBOARD_PORT=9119 \
    HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin \
    PORT=9119

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

EXPOSE 9119

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
# Upstream's main-wrapper routes an executable first arg straight to exec, so the
# container's main program is a no-op and the dashboard runs as the supervised s6
# service. This is the upstream-documented way to run dashboard-only.
CMD ["sleep", "infinity"]
