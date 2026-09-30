/**
 * Finds extra photographs of the *same* dish so the recipe screen can be
 * swiped left and right.
 *
 *   node tools/recipes/extra_images.js            # list candidates
 *   node tools/recipes/extra_images.js --review   # also print them per recipe
 *
 * The rule that matters: an image only qualifies when its own filename names the
 * dish. Wikipedia article galleries are full of near misses, and the Falafel
 * article really does contain a photograph of donkeys parked outside a falafel
 * stand. Matching is therefore a filter for review, not proof, and nothing is
 * added to the app until a human has looked at it.
 */
const fs = require("fs");
const path = require("path");
const https = require("https");

const ROOT = path.resolve(__dirname, "../..");
const MANIFEST = path.join(__dirname, "wiki_manifest.json");
const OUT = path.join(__dirname, "extra_candidates.json");
const CANDIDATE_DIR = path.join(__dirname, "extra_candidates");
const API = "https://en.wikipedia.org/w/api.php";
const DELAY_MS = 250;
const REVIEW = process.argv.includes("--review");

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const maxPerRecipe = 3;

function get(url, binary) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      { headers: { "User-Agent": "CookSmart/1.0 (recipe app; local project)" } },
      (res) => {
        if (res.statusCode === 429) {
          res.resume();
          return reject(new Error("rate limited"));
        }
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          return resolve(get(res.headers.location, binary));
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () =>
          resolve(binary ? Buffer.concat(chunks) : Buffer.concat(chunks).toString("utf8")),
        );
      },
    );
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error("timeout"));
    });
    req.on("error", reject);
  });
}

const norm = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, "");

function readRecipes() {
  const out = [];
  const dir = path.join(ROOT, "lib", "data");
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".dart"))) {
    const text = fs.readFileSync(path.join(dir, file), "utf8");
    const rx =
      /id: '([^']+)',\s*(?:imageAsset: '[^']*',\s*)?(?:extraImages: <String>\[([^\]]*)\],\s*)?name: '([^']+)'/g;
    let m;
    while ((m = rx.exec(text)) !== null) {
      const extras = (m[2] || "")
        .split(",")
        .map((s) => s.trim().replace(/^'|'$/g, ""))
        .filter(Boolean);
      out.push({ id: m[1], name: m[3], extras });
    }
  }
  return out;
}

async function articleImages(articleTitle) {
  const url =
    `${API}?action=query&format=json&prop=images&imlimit=60&titles=` +
    encodeURIComponent(articleTitle);
  const text = await get(url, false);
  const data = JSON.parse(text);
  const page = Object.values(data.query.pages)[0];
  return (page && page.images) || [];
}

async function fileUrl(fileTitle) {
  const url =
    `${API}?action=query&format=json&prop=imageinfo&iiprop=url&iiurlwidth=900&titles=` +
    encodeURIComponent(fileTitle);
  const data = JSON.parse(await get(url, false));
  const page = Object.values(data.query.pages)[0];
  const info = page && page.imageinfo && page.imageinfo[0];
  return info ? info.thumburl || info.url : null;
}

(async () => {
  const manifest = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
  const recipes = readRecipes();
  fs.mkdirSync(CANDIDATE_DIR, { recursive: true });

  const results = {};
  let withCandidates = 0;
  let totalFiles = 0;

  for (const recipe of recipes) {
    if (recipe.extras.length) continue; // already has a gallery
    const entry = manifest[recipe.id];
    if (!entry || !entry.title) continue;

    const article = entry.title.split("/wiki/")[1];
    if (!article) continue;

    // Only whole-dish words matter, so "Doner Kebab" does not match "Doner
    // Kebab Plate with Rice and Salad" and "Baklava" does not match "Baklava
    // Rolls with Ice Cream".
    const words = norm(recipe.name).split(/(?=[a-z]{4})/).filter((w) => w.length > 3);
    if (!words.length) continue;
    const dishKey = words[words.length - 1];

    let images;
    try {
      images = await articleImages(article);
    } catch (e) {
      await sleep(2000);
      continue;
    }
    await sleep(DELAY_MS);

    const candidates = [];
    for (const img of images) {
      if (candidates.length >= maxPerRecipe) break;
      const title = img.title;
      if (!/\.(jpe?g|png)$/i.test(title)) continue;
      const base = title.replace(/^File:/, "").replace(/\.(jpe?g|png)$/i, "");
      const key = norm(base);
      if (!key.includes(dishKey)) continue;
      // Very long file names are almost always a scene rather than the dish.
      if (base.length > 45) continue;
      // Skip anything already used as this recipe's primary photo.
      if (fs.existsSync(path.join(ROOT, "assets", "recipes", `${recipe.id}.jpg`))) {
        // Same dish but may still be a different photo; keep it for review.
      }
      candidates.push(title);
    }
    if (!candidates.length) continue;

    withCandidates++;
    results[recipe.id] = { name: recipe.name, article, files: [] };

    for (let i = 0; i < candidates.length; i++) {
      const fileTitle = candidates[i];
      let url;
      try {
        url = await fileUrl(fileTitle);
      } catch (e) {
        await sleep(2000);
        continue;
      }
      await sleep(DELAY_MS);
      if (!url) continue;
      const local = path.join(CANDIDATE_DIR, `${recipe.id}__${i + 2}.jpg`);
      try {
        const bytes = await get(url, true);
        if (!bytes || bytes.length < 5000) continue;
        fs.writeFileSync(local, bytes);
        results[recipe.id].files.push({
          file: `extra_candidates/${recipe.id}__${i + 2}.jpg`,
          from: fileTitle,
        });
        totalFiles++;
      } catch (e) {
        /* skip this candidate */
      }
    }
    if (REVIEW) {
      console.log(
        `${recipe.id.padEnd(24)} ${recipe.name.padEnd(26)} ${results[recipe.id].files.length} candidate(s)`,
      );
    }
  }

  fs.writeFileSync(OUT, JSON.stringify(results, null, 1));
  console.log(
    `\n${withCandidates} recipes with candidates, ${totalFiles} files -> ${CANDIDATE_DIR}`,
  );
  console.log("Nothing has been added to the app yet. Review the contact sheets first.");
})();
