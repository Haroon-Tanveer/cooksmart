// Copies the app's privacy.html into the publishable site folder, applying the
// small differences a hosted page wants: a clearer <title> and a meta
// description for search results.
//
//   node tools/privacy/build_site.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SOURCE = path.join(ROOT, "privacy.html");
const TARGET = path.join(ROOT, "..", "privacy-site", "index.html");

const DESCRIPTION =
  "How CookSmart handles your data: no account, no tracking, no advertising, " +
  "and nothing leaves your device unless you turn on live generation.";

let html = fs.readFileSync(SOURCE, "utf8");

if (/<meta\s+name="description"/.test(html)) {
  console.log("already has a description, leaving head alone");
} else {
  html = html
    .replace(
      "<title>Privacy Policy — CookSmart</title>",
      `<title>CookSmart — Privacy Policy</title>\n` +
        `<meta name="description" content="${DESCRIPTION}">`,
    );
  html = html.replace(
    "<title>Privacy Policy</title>",
    `<title>CookSmart — Privacy Policy</title>\n` +
      `<meta name="description" content="${DESCRIPTION}">`,
  );
}

fs.mkdirSync(path.dirname(TARGET), { recursive: true });
fs.writeFileSync(TARGET, html, "utf8");

const report = {
  scripts: (html.match(/<script/gi) || []).length,
  externalImages: (html.match(/<img[^>]+src="https?:/gi) || []).length,
  outboundLinks: (html.match(/<a[^>]+href="https?:/gi) || []).length,
  styleBlocks: (html.match(/<style>/gi) || []).length,
  bytes: html.length,
};

console.log("wrote", TARGET);
console.log("  scripts        :", report.scripts);
console.log("  external images:", report.externalImages);
console.log("  outbound links :", report.outboundLinks);
console.log("  style blocks   :", report.styleBlocks);
console.log("  bytes          :", report.bytes);
