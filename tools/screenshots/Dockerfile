# Pin browser binaries, OS libraries and fonts together. Keep the npm Playwright
# version in package.json equal to this image's version when upgrading.
FROM mcr.microsoft.com/playwright:v1.64.1-noble@sha256:47b510dd9230bf0b9bfc9b20102241e577ea7a99334ab4c3ca19f19770e9b8ea
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY compare.mjs compare.test.mjs validation.mjs validation.test.mjs render.mjs ./
RUN node --test compare.test.mjs validation.test.mjs
ENV HOME=/tmp
ENTRYPOINT ["node", "/app/render.mjs"]
