# Bakes a small Amsterdam-only Protomaps extract into tileserver-gl-light, so the data
# ships in the image (no PVC / init container / runtime download). Rebuild to refresh.

# Extract just the Amsterdam region from the public Protomaps daily build. The go-pmtiles
# image is distroless (no shell) and its binary is /go-pmtiles, so use exec-form RUN and
# write to / (WORKDIR). `extract` only pulls the bbox via HTTP range requests (small/fast).
# Exec form does no var substitution — bump the date here to refresh. https://build.protomaps.com/
FROM protomaps/go-pmtiles:v1.30.3 AS data
RUN ["/go-pmtiles", "extract", \
     "https://build.protomaps.com/20260615.pmtiles", \
     "/amsterdam.pmtiles", \
     "--bbox=4.693909,52.247983,5.090790,52.452662"]

# Serve it in config mode. `--file` auto mode only serves the raw data (no style), so we bake
# a config + a Protomaps-v4 light style.json that sources the local `amsterdam` data, and copy
# the image's bundled glyph fonts into the data root so labels render. --public_url makes the
# emitted style/tilejson/font URLs absolute under /tiles/ so they route back through the ingress
# (which strips the prefix). Style is served at /tiles/styles/amsterdam/style.json.
FROM maptiler/tileserver-gl-light:v5.6.0
COPY --from=data --chown=node:node /amsterdam.pmtiles /data/data/amsterdam.pmtiles
COPY --chown=node:node config.json /data/config.json
COPY --chown=node:node styles /data/styles
COPY --chown=node:node fonts /data/fonts
EXPOSE 8080
CMD ["-c", "/data/config.json"]
