# CookSmart Gemini proxy.
#
# The Gemini key is read at run time from GEMINI_API_KEY and never baked into the
# image, so the same image can be promoted between environments safely.
FROM node:22-alpine

WORKDIR /app

# Only the proxy is needed here; the Flutter app is built separately.
COPY tool/server/gemini_proxy.js ./gemini_proxy.js

ENV PORT=8787
ENV GEMINI_MODELS=gemini-3.8-flash,gemini-3-flash-preview,gemini-flash-latest
EXPOSE 8787

# Render, Railway and Fly all inject PORT; the proxy honours it.
CMD ["node", "gemini_proxy.js"]
