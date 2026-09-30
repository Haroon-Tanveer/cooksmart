/**
 * CookSmart app icon generator.
 *
 * Renders the chef's-hat mark with the headless browser already on this machine
 * (Playwright + Edge) and writes every platform asset:
 *   - Android legacy mipmaps + adaptive icon foreground/background
 *   - Web favicon, PWA icons and maskable icons
 *   - Windows runner .ico
 *
 * Usage: node tools/icon/generate-icons.js
 */
const fs = require("fs");
const path = require("path");
const { chromium } = require("C:/Users/haroo/node_modules/playwright");

const ROOT = path.resolve(__dirname, "../..");
const ANDROID_RES = path.join(ROOT, "android/app/src/main/res");

/* ------------------------------------------------------------------ */
/* The mark: three toque puffs + band, on a dark tile with a warm glow. */
/* ------------------------------------------------------------------ */

const HAT = `
  <g transform="translate(512 512) scale(\${SCALE}) translate(-512 -572)">
    <g clip-path="url(#puffs)">
      <rect x="120" y="300" width="784" height="300" fill="url(#hat)"/>
    </g>
    <rect x="340" y="600" width="344" height="150" rx="28" fill="#FFF6EE"/>
  </g>`;

function svg({
  hatScale = 1,
  tile = true,
  radius = 224,
  glow = false,
  glowOpacity = 0.32,
  glowRadius = 0.5,
}) {
  const defs = `
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
      <radialGradient id="glow" cx="0.84" cy="0.04" r="${glowRadius}">
        <stop offset="0" stop-color="#FF8A3D" stop-opacity="${glowOpacity}"/>
        <stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="hat" gradientUnits="userSpaceOnUse"
                      x1="330" y1="400" x2="700" y2="700">
        <stop offset="0" stop-color="#FFD09E"/>
        <stop offset="0.5" stop-color="#FF9C55"/>
        <stop offset="1" stop-color="#EC6816"/>
      </linearGradient>
    </defs>`;

  const background = tile
    ? `<rect width="1024" height="1024" rx="${radius}" fill="url(#tile)"/>
       <rect width="1024" height="1024" rx="${radius}" fill="url(#glow)"/>`
    : glow
      ? `<rect width="1024" height="1024" fill="url(#glow)"/>`
      : "";

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
    ${defs}${background}${HAT.replace("${SCALE}", hatScale)}
  </svg>`;
}

const VARIANTS = {
  // Legacy launcher / desktop tile: rounded corners baked in.
  tile: () => svg({ hatScale: 1, tile: true, radius: 224 }),
  // Round launcher icon for pre-API-26 devices that honour android:roundIcon.
  round: () => svg({ hatScale: 0.86, tile: true, radius: 512 }),
  // Android adaptive foreground: transparent, logo inside the 66% safe zone.
  adaptive: () =>
    svg({ hatScale: 0.78, tile: false, glow: true, glowOpacity: 0.16, glowRadius: 0.6 }),
  // PWA maskable: full bleed background, logo inside the 80% safe circle.
  maskable: () => svg({ hatScale: 0.58, tile: true, radius: 0 }),
};

/* ------------------------------------------------------------------ */

const jobs = [
  // Android legacy launcher icons
  ["android/app/src/main/res/mipmap-mdpi/ic_launcher.png", "tile", 48],
  ["android/app/src/main/res/mipmap-hdpi/ic_launcher.png", "tile", 72],
  ["android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", "tile", 96],
  ["android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", "tile", 144],
  ["android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", "tile", 192],

  // Android round launcher icons
  ["android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png", "round", 48],
  ["android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png", "round", 72],
  ["android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png", "round", 96],
  ["android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png", "round", 144],
  ["android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png", "round", 192],

  // Android adaptive icon foreground (108dp canvas)
  ["android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png", "adaptive", 108],
  ["android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png", "adaptive", 162],
  ["android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png", "adaptive", 216],
  ["android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png", "adaptive", 324],
  ["android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png", "adaptive", 432],

  // Web
  ["web/favicon.png", "tile", 64],
  ["web/icons/Icon-192.png", "tile", 192],
  ["web/icons/Icon-512.png", "tile", 512],
  ["web/icons/Icon-maskable-192.png", "maskable", 192],
  ["web/icons/Icon-maskable-512.png", "maskable", 512],
];

const ICO_SIZES = [16, 24, 32, 48, 64, 128, 256];

async function renderAll(browser) {
  const page = await browser.newPage();
  for (const [rel, variant, size] of jobs) {
    const markup = VARIANTS[variant]();
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(
      `<html><body style="margin:0;background:transparent">${markup}</body></html>`,
      { waitUntil: "load" }
    );
    const svgEl = await page.$("svg");
    const out = path.join(ROOT, rel);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    await svgEl.screenshot({ path: out, omitBackground: true });
    console.log("  wrote", rel, `${size}x${size}`);
  }

  // Windows .ico needs the raw PNG bytes, so keep them around.
  const icoPngs = [];
  for (const size of ICO_SIZES) {
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(
      `<html><body style="margin:0;background:transparent">${VARIANTS.tile()}</body></html>`,
      { waitUntil: "load" }
    );
    const buf = await (await page.$("svg")).screenshot({ omitBackground: true });
    icoPngs.push({ size, buf });
  }
  await page.close();
  return icoPngs;
}

function buildIco(entries) {
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type: icon
  header.writeUInt16LE(entries.length, 4);

  const dir = Buffer.alloc(16 * entries.length);
  let offset = header.length + dir.length;

  entries.forEach((entry, i) => {
    const at = i * 16;
    dir.writeUInt8(entry.size >= 256 ? 0 : entry.size, at); // width (0 == 256)
    dir.writeUInt8(entry.size >= 256 ? 0 : entry.size, at + 1); // height
    dir.writeUInt8(0, at + 2); // palette size
    dir.writeUInt8(0, at + 3); // reserved
    dir.writeUInt16LE(1, at + 4); // color planes
    dir.writeUInt16LE(32, at + 6); // bits per pixel
    dir.writeUInt32LE(entry.buf.length, at + 8);
    dir.writeUInt32LE(offset, at + 12);
    offset += entry.buf.length;
  });

  return Buffer.concat([header, dir, ...entries.map((e) => e.buf)]);
}

(async () => {
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

  console.log("rendering icons…");
  const icoPngs = await renderAll(browser);
  await browser.close();

  const ico = buildIco(icoPngs);
  fs.writeFileSync(path.join(ROOT, "windows/runner/resources/app_icon.ico"), ico);
  console.log("  wrote windows/runner/resources/app_icon.ico", ico.length, "bytes");

  // Adaptive icon background colour + gradient layer.
  fs.writeFileSync(
    path.join(ANDROID_RES, "values/colors.xml"),
    `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#14100C</color>
</resources>
`
  );

  fs.writeFileSync(
    path.join(ANDROID_RES, "drawable/ic_launcher_background.xml"),
    `<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="135"
        android:startColor="#1C150F"
        android:centerColor="#120E0A"
        android:endColor="#080706"
        android:type="linear" />
</shape>
`
  );

  const adaptiveXml = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
`;
  const anydpi = path.join(ANDROID_RES, "mipmap-anydpi-v26");
  fs.mkdirSync(anydpi, { recursive: true });
  fs.writeFileSync(path.join(anydpi, "ic_launcher.xml"), adaptiveXml);
  fs.writeFileSync(path.join(anydpi, "ic_launcher_round.xml"), adaptiveXml);
  console.log("  wrote adaptive icon xml + colors.xml");
})();
