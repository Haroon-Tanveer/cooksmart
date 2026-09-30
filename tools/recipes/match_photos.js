/**
 * Matches every library recipe against the TheMealDB catalogue and writes the
 * ones that are genuinely the same dish to tools/recipes/photo_manifest.json.
 *
 *   node tools/recipes/match_photos.js          # write the manifest
 *   node tools/recipes/match_photos.js --review # also print near-misses
 *
 * Only confident matches are accepted. A photo of the wrong dish is worse than
 * no photo, so anything ambiguous is reported for review rather than guessed.
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const CATALOGUE = path.join(__dirname, "catalogue.json");
const MANIFEST = path.join(__dirname, "photo_manifest.json");
const REVIEW = process.argv.includes("--review");

/** Words too common to carry meaning when comparing two dish names. */
const STOP = new Set([
  "with", "and", "the", "a", "of", "in", "on", "style", "sauce", "salad", "soup",
  "cake", "pie", "tart", "pudding", "rice", "bread", "chicken", "lamb", "beef",
  "stuffed", "baked", "fry", "fried", "grilled", "sweet", "spicy", "easy", "home",
  "made", "classic", "turkish", "arabian", "vegan", "quick", "hot", "creamy",
  "baste", "chops", "roast", "honey", "tuna", "egg", "pork", "potato", "spicy",
]);

const norm = (s) =>
  s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ş/g, "s")
    .replace(/ç/g, "c")
    .replace(/ö/g, "o")
    .replace(/ü/g, "u")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const tokens = (s) => norm(s).split(" ").filter((t) => t.length > 1 && !STOP.has(t));

/** Pulls id/name pairs out of the recipe data files. */
function readRecipes() {
  const dir = path.join(ROOT, "lib", "data");
  const out = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".dart"))) {
    const text = fs.readFileSync(path.join(dir, file), "utf8");
    const rx = /id: '([^']+)',\s*(?:imageAsset: '[^']*',\s*)?name: '([^']+)'/g;
    let m;
    while ((m = rx.exec(text)) !== null) out.push({ id: m[1], name: m[2], file });
  }
  return out;
}

/**
 * Confidence that a recipe and a catalogue meal are the same dish.
 * 2 = certain, 1 = plausible, 0 = no.
 */
function score(recipeName, mealName) {
  const a = tokens(recipeName);
  const b = tokens(mealName);
  if (!a.length || !b.length) return { level: 0, why: "no tokens" };

  // The head of the name is the dish itself: "adana kebab" -> "kebab".
  const headA = a[a.length - 1];
  const headB = b[b.length - 1];
  const headMatch = headA === headB;

  const setB = new Set(b);
  const shared = a.filter((t) => setB.has(t));
  const coverage = shared.length / a.length;

  if (norm(recipeName) === norm(mealName)) return { level: 2, why: "exact" };
  if (headMatch && coverage >= 0.99) return { level: 2, why: `same head, all tokens` };
  if (headMatch && coverage >= 0.5) return { level: 1, why: `head + ${shared.length}/${a.length}` };
  if (coverage === 1 && a.length >= 2) return { level: 1, why: "all tokens, different head" };
  return { level: 0, why: `${shared.length}/${a.length} shared` };
}

const catalogue = JSON.parse(fs.readFileSync(CATALOGUE, "utf8"));
const recipes = readRecipes();
const manifest = {};
const nearMisses = [];

for (const r of recipes) {
  let best = { level: 0 };
  let bestMeal = null;
  for (const meal of catalogue) {
    const s = score(r.name, meal.name);
    if (s.level > best.level) {
      best = s;
      bestMeal = meal;
    }
  }
  if (best.level === 2) {
    manifest[r.id] = bestMeal.name;
  } else if (best.level === 1) {
    nearMisses.push({ id: r.id, recipe: r.name, meal: bestMeal.name, why: best.why });
  }
}

fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 1));
console.log(
  `${recipes.length} recipes checked against ${catalogue.length} catalogue meals`
);
console.log(`${Object.keys(manifest).length} confident matches written to photo_manifest.json`);
console.log(`${nearMisses.length} plausible but unconfirmed, left without a photo`);
if (REVIEW) {
  for (const n of nearMisses) {
    console.log(`  ? ${n.recipe.padEnd(32)} ~ ${n.meal.padEnd(32)} (${n.why})`);
  }
}
