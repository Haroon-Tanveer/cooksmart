/**
 * Fetches the whole TheMealDB catalogue by searching each letter, then writes
 * it to tools/recipes/catalogue.json.
 *
 *   node tools/recipes/catalogue.js
 *
 * Matching by hand is what limited us to 39 photos: every dish name has to be
 * guessed as a search term. Having all ~300 real meal names lets the matcher
 * compare them against the whole library at once.
 */
const fs = require("fs");
const https = require("https");
const path = require("path");

const OUT = path.join(__dirname, "catalogue.json");
const alphabet = "abcdefghijklmnopqrstuvwxyz".split("");

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
  const byId = new Map();
  for (const letter of alphabet) {
    const data = await get(
      `https://www.themealdb.com/api/json/v1/1/search.php?s=${letter}`
    );
    const meals = (data && data.meals) || [];
    for (const m of meals) {
      if (m.strMeal && m.strMealThumb) byId.set(m.idMeal, m.strMeal + "|" + m.strMealThumb);
    }
    process.stdout.write(letter + " ");
  }

  const meals = [...byId.entries()].map(([id, packed]) => {
    const [name, thumb] = packed.split("|");
    return { id, name, thumb };
  });

  fs.writeFileSync(OUT, JSON.stringify(meals, null, 1));
  console.log(`\n${meals.length} unique meals -> ${OUT}`);
})();
