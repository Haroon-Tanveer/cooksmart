// Lists several TheMealDB matches for a term, so a better photo can be picked.
//   node tools/recipes/probe_all.js shrimp risotto "tomato soup" "black bean" tea lemonade
const https = require("https");

const get = (url) =>
  new Promise((resolve) => {
    https
      .get(url, (res) => {
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
    const data = await get(
      `https://www.themealdb.com/api/json/v1/1/search.php?s=${encodeURIComponent(term)}`
    );
    const meals = ((data && data.meals) || []).slice(0, 8);
    console.log(`\n== ${term} ==`);
    meals.forEach((m, i) => console.log(`  ${i}. ${m.strMeal} [${m.strMealCategory}]`));
    if (!meals.length) console.log('  (no matches)');
  }
})();
