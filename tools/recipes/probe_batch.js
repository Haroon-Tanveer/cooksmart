// Checks a list of candidate dish names against TheMealDB and reports which
// have a real photograph available, so recipe data can be written for the ones
// that can actually be illustrated.
//   node tools/recipes/probe_batch.js "Chicken Mansaf" "Koshari" "Tagine"
const fs = require("fs");
const https = require("https");
const path = require("path");

const CANDIDATES = JSON.parse(
  fs.readFileSync(path.join(__dirname, "candidates.json"), "utf8")
);

function get(url) {
  return new Promise((resolve) => {
    https
      .get(url, { headers: { "User-Agent": "CookSmart/1.0" } }, (res) => {
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
}

(async () => {
  const hits = {};
  const misses = [];
  const list = Array.isArray(CANDIDATES) ? CANDIDATES : [];
  for (const term of list) {
    const data = await get(
      `https://www.themealdb.com/api/json/v1/1/search.php?s=${encodeURIComponent(term)}`
    );
    const meals = (data && data.meals) || [];
    if (meals.length && meals[0].strMealThumb) {
      hits[term] = meals[0].strMeal;
    } else {
      misses.push(term);
    }
  }
  console.log(`\nWITH PHOTOS (${Object.keys(hits).length}):`);
  for (const [term, matched] of Object.entries(hits)) {
    console.log(`  ${term.padEnd(26)} -> ${matched}`);
  }
  console.log(`\nNO PHOTO (${misses.length}): ${misses.join(', ')}`);
})();
