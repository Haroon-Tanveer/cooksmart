/**
 * Downloads a real photograph for every bundled recipe.
 *
 *   node tools/recipes/fetch_images.js
 *
 * Photos come from TheMealDB's free API, which is the only image host this
 * project can reach. Each entry maps a recipe id to the dish name to search
 * for, so the picture always matches the recipe. Files land in
 * assets/recipes/<id>.jpg and are referenced by `imageAsset` in recipes.dart.
 *
 * Re-running is cheap: an existing, non-empty file is skipped. Pass --force to
 * download everything again.
 */
const fs = require("fs");
const https = require("https");
const path = require("path");

const OUT = path.join(__dirname, "..", "..", "assets", "recipes");
const API = "https://www.themealdb.com/api/json/v1/1/search.php?s=";
const FORCE = process.argv.includes("--force");

/** id -> dish name to look for on TheMealDB. */
const MANIFEST = {
  // Existing library recipes.
  "garlic-butter-shrimp": "Jamaican Pepper Shrimp",
  "spinach-tomato-pasta": "Arrabiata",
  "veggie-egg-fried-rice": "Fried Rice",
  "creamy-tomato-soup": "Tomato Soup",
  "sheet-pan-chicken": "Chicken",
  "loaded-breakfast-hash": "Breakfast Potatoes",
  "banana-pancakes": "Pancakes",
  "black-bean-bowl": "Black Beans Hotpot",
  "mushroom-risotto": "Salmon Prawn Risotto",
  "molten-chocolate-cake": "Vegan Chocolate Cake",
  // No tea photograph exists on TheMealDB, so this recipe ships with the brand
  // gradient and its emoji instead of a misleading stand-in.
  "garlic-noodles": "Laksa King Prawn Noodles",
  "peanut-noodles": "Drunken noodles",
  "roasted-veg-frittata": "French Omelette",

  // Arabian.
  "chicken-shawarma": "Shawarma",
  falafel: "Falafel",
  hummus: "Hummus",
  baklava: "Baklava",
  knafeh: "Knafeh",
  "chicken-mandi": "Chicken Mandi",
  "stuffed-grape-leaves": "Stuffed Grape Leaves",

  // Turkish.
  "adana-kebab": "Adana kebab",
  "turkish-lahmacun": "Turkish lahmacun",
  cacik: "Cacik",

  // Fast food.
  "aussie-burger": "Aussie Burgers",
  "margherita-pizza": "Pizza Express Margherita",
  "kentucky-fried-chicken": "Kentucky Fried Chicken",
  "crispy-wings": "Extra crispy chicken wings",
  "chicken-tacos": "Crock Pot Chicken Baked Tacos",
  "krispy-donut": "Krispy Kreme Donut",
  "cuban-sandwich": "Cuban Sandwich",

  // Arabian batch: only the dishes TheMealDB genuinely has a photo of. The
  // rest keep the brand gradient and their emoji, which is better than a
  // picture of some other food.
  "baba-ghanoush": "Baba Ghanoush",
  fatteh: "Fatteh",
  koshari: "Koshari",
  "lamb-tagine": "Tagine",
  "chicken-couscous": "Couscous",
  "chorba-frik": "Chorba",
  shakshuka: "Shakshuka",
  "brik-a-tuna": "Brik",
  "kelem-dolmasi": "Dolma",
};

const get = (url, binary) =>
  new Promise((resolve) => {
    https
      .get(url, { headers: { "User-Agent": "CookSmart/1.0" } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          return resolve(get(res.headers.location, binary));
        }
        if (res.statusCode !== 200) {
          res.resume();
          return resolve(null);
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => resolve(binary ? Buffer.concat(chunks) : Buffer.concat(chunks).toString("utf8")));
      })
      .on("error", () => resolve(null));
  });

async function findThumb(dish) {
  const raw = await get(API + encodeURIComponent(dish));
  if (!raw) return null;
  try {
    const meals = JSON.parse(raw).meals;
    if (!meals || !meals.length) return null;
    // TheMealDB returns the closest matches first; the first usable thumb wins.
    const hit = meals.find((m) => m.strMealThumb) || null;
    return hit ? { url: hit.strMealThumb, name: hit.strMeal } : null;
  } catch (_) {
    return null;
  }
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  let ok = 0;
  const failed = [];

  for (const [id, dish] of Object.entries(MANIFEST)) {
    const file = path.join(OUT, `${id}.jpg`);
    if (!FORCE && fs.existsSync(file) && fs.statSync(file).size > 2000) {
      ok++;
      continue;
    }
    const found = await findThumb(dish);
    if (!found) {
      failed.push(`${id} (${dish}): no match on TheMealDB`);
      continue;
    }
    const bytes = await get(found.url, true);
    if (!bytes || bytes.length < 2000) {
      failed.push(`${id} (${dish}): download failed`);
      continue;
    }
    fs.writeFileSync(file, bytes);
    console.log(`  ${id.padEnd(28)} ${(bytes.length / 1024).toFixed(0).padStart(5)} KB  ${found.name}`);
    ok++;
;
  }

  console.log(`\n${ok}/${Object.keys(MANIFEST).length} photos in ${OUT}`);
  if (failed.length) {
    console.log("\nNEEDS A DIFFERENT SEARCH TERM:");
    failed.forEach((f) => console.log(`  ${f}`));
    process.exitCode = 1;
  }
})();
