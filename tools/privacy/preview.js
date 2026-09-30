// Renders privacy.html in a real browser and screenshots it, so the page that
// gets published is checked rather than assumed.
//   node tools/privacy/preview.js
const path = require("path");
const fs = require("fs");
const { chromium } = require("C:/Users/haroo/node_modules/playwright");

const ROOT = path.resolve(__dirname, "../..");
const OUT = path.join(ROOT, "store");

async function main() {
  fs.mkdirSync(OUT, { recursive: true });

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

  const page = await browser.newPage({ viewport: { width: 1000, height: 1400 } });
  const file = "file:///" + path.join(ROOT, "privacy.html").replace(/\\/g, "/");
  await page.goto(file, { waitUntil: "load" });

  const problems = await page.evaluate(() => ({
    scripts: document.querySelectorAll("script").length,
    externalImages: [...document.images]
      .filter((i) => !i.src.startsWith("file:") && i.src)
      .map((i) => i.src),
    links: [...document.querySelectorAll("a")].map((a) => a.href),
    headings: [...document.querySelectorAll("h2")].map((h) => h.textContent.trim()),
    textLength: document.body.innerText.length,
  }));

  console.log("external scripts :", problems.scripts);
  console.log("external images :", problems.externalImages.length);
  console.log("outbound links  :", problems.links.length);
  console.log("sections        :", problems.headings.join(" | "));
  console.log("rendered chars  :", problems.textLength);

  const target = path.join(OUT, "privacy-page-preview.png");
  await page.screenshot({ path: target, fullPage: true });
  await browser.close();
  console.log("\npreview written to", target);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
