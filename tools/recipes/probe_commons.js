// Probe Wikimedia Commons for real photos of dishes TheMealDB does not have.
//   node tools/recipes/probe_commons.js pide manti "french fries"
const https = require("https");

const get = (url) =>
  new Promise((resolve) => {
    https
      .get(url, { headers: { "User-Agent": "CookSmart/1.0 (recipe app)" } }, (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          try {
            resolve(JSON.parse(raw));
          } catch (_) {
            resolve(null);
          }
        });
      })
      .on("error", () => resolve(null));
  });

(async () => {
  for (const term of process.argv.slice(2)) {
    const url =
      `https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search` +
      `&gsrnamespace=6&gsrlimit=5&gsrsearch=${encodeURIComponent(term)}` +
      `&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=900`;
    const data = await get(url);
    const pages = (data && data.query && data.query.pages) || {};
    const list = Object.values(pages);
    console.log(`\n== ${term} ==`);
    for (const p of list) {
      const info = (p.imageinfo || [])[0] || {};
      console.log(`  ${p.title}  ->  ${info.thumburl || info.url || 'no url'}`);
    }
  }
})();
