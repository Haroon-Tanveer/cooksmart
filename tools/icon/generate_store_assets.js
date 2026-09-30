/**
 * Google Play store artwork.
 *
 *   node tools/icon/generate_store_assets.js
 *
 * Writes:
 *   store/icon-512.png            the 512x512 store icon (Play's hard requirement)
 *   store/feature-graphic.png     the 1024x500 banner that sits behind the app name
 *
 * Both are rendered from the same mark as the launcher icon rather than being
 * upscaled from a PNG, so they stay crisp. The feature graphic is written as a
 * 24-bit PNG with no alpha channel, which is what Play accepts for it.
 */
const fs = require("fs");
const path = require("path");
const { chromium } = require("C:/Users/haroo/node_modules/playwright");

const ROOT = path.resolve(__dirname, "../..");
const OUT = path.join(ROOT, "store");

const DEFS = `
  <defs>
    <clipPath id="puffs">
      <ellipse cx="352" cy="600" rx="178" ry="168"/>
      <ellipse cx="512" cy="600" rx="210" ry="205"/>
      <ellipse cx="672" cy="600" rx="178" ry="168"/>
    </clipPath>
    <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#141009"/>
      <stop offset="1" stop-color="#070605"/>
    </linearGradient>
    <linearGradient id="banner" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#1A120B"/>
      <stop offset="0.55" stop-color="#241608"/>
      <stop offset="1" stop-color="#0C0806"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.16" cy="0.1" r="0.7">
      <stop offset="0" stop-color="#FF8A3D" stop-opacity="0.34"/>
      <stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="hat" gradientUnits="userSpaceOnUse"
                    x1="330" y1="400" x2="700" y2="700">
      <stop offset="0" stop-color="#FFD09E"/>
      <stop offset="0.5" stop-color="#FF9C55"/>
      <stop offset="1" stop-color="#EC6816"/>
    </linearGradient>
  </defs>`;

function hat(translateX, scale) {
  return `
    <g transform="translate(${translateX} 0) scale(${scale})">
      <g clip-path="url(#puffs)">
        <rect x="120" y="300" width="784" height="300" fill="url(#hat)"/>
      </g>
      <rect x="340" y="600" width="344" height="150" rx="28" fill="#FFF6EE"/>
    </g>`;
}

/** 512x512 store icon: the launcher mark, full bleed, no transparency. */
function storeIcon() {
  return `
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
    ${DEFS}
    <rect width="1024" height="1024" fill="url(#tile)"/>
    <rect width="1024" height="1024" fill="url(#glow)"/>
    ${hat(0, 1)}
  </svg>`;
}

/** 1024x500 feature graphic: mark, wordmark, one line of what it does. */
function featureGraphic() {
  return `
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 500" width="1024" height="500">
    ${DEFS}
    <rect width="1024" height="500" fill="url(#banner)"/>
    <rect width="1024" height="500" fill="url(#glow)"/>

    <g transform="translate(52 56) scale(0.36)">
      <rect x="0" y="0" width="1024" height="1024" rx="210" fill="url(#tile)"/>
      ${hat(0, 1)}
    </g>

    <text x="452" y="236" fill="#FFF6EE"
          font-family="Segoe UI, Roboto, Helvetica, Arial, sans-serif"
          font-size="78" font-weight="800" letter-spacing="-1">CookSmart</text>
    <text x="454" y="300" fill="#FF9C55"
          font-family="Segoe UI, Roboto, Helvetica, Arial, sans-serif"
          font-size="25" font-weight="600">560 recipes · calories · cooking steps</text>
  </svg>`;
}

const JOBS = [
  { file: "icon-512.png", markup: storeIcon, size: 512 },
  { file: "feature-graphic.png", markup: featureGraphic, size: 1024 },
];

async function main() {
  fs.mkdirSync(OUT, { recursive: true });

  // Playwright's own browser may not be downloaded, so fall back to an
  // installed Chromium the way the launcher icon generator does.
  let browser;
  let lastError;
  for (const opts of [{ channel: "msedge" }, { channel: "chrome" }, {}]) {
    try {
      browser = await chromium.launch(opts);
      break;
    } catch (e) {
      lastError = e;
    }
  }
  if (!browser) throw lastError;

  for (const job of JOBS) {
    const page = await browser.newPage();
    const width = job.size;
    const height = job.file.startsWith("feature") ? 500 : 512;
    await page.setViewportSize({ width, height });
    await page.setContent(
      `<html><body style="margin:0;background:#000">${job.markup()}</body></html>`,
      { waitUntil: "load" },
    );
    const target = path.join(OUT, job.file);
    if (job.file.startsWith("feature")) {
      // Play wants a 24-bit PNG here, so fill the background rather than
      // relying on transparency.
      await page.screenshot({ path: target, type: "png", omitBackground: false });
    } else {
      const el = await page.$("svg");
      await el.screenshot({ path: target, type: "png", omitBackground: false });
    }
    await page.close();
    const kb = Math.round(fs.statSync(target).size / 1024);
    console.log(`  ${job.file.padEnd(22)} ${width}x${height}  ${kb} KB`);
  }

  await browser.close();
  console.log(`\nstore artwork written to ${OUT}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
