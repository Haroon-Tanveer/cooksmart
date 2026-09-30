// Probe TheMealDB for dishes we want real photos of.
//   node tools/recipes/probe.js shawarma falafel baklava "ice cream"
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
    const url = `https://www.themealdb.com/api/json/v1/1/search.php?s=${encodeURIComponent(term)}`;
    const data = await get(url);
    const meals = (data && data.meals) || [];
    console.log(
      `${term.padEnd(22)} ${meals.length ? meals.slice(0, 3).map((m) => m.strMeal).join(' | ') : 'NO MATCH'}`
    );
  }
})();
