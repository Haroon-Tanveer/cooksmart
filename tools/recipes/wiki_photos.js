/**
 * Sourced a real photograph for every library recipe from Wikipedia.
 *
 *   node tools/recipes/wiki_photos.js            # fill the gaps
 *   node tools/recipes/wiki_photos.js --force    # redo everything
 *
 * TheMealDB only holds 227 mostly British and American meals, so it cannot
 * cover this library. Wikipedia has curated, correctly-labelled photographs of
 * the dishes themselves, and records who took them and under what licence, so
 * this writes the credits out alongside the images.
 *
 * Requests are throttled and retried: the API answers 429 quickly if you
 * hammer it.
 */
const fs = require("fs");
const https = require("https");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const OUT_DIR = path.join(ROOT, "assets", "recipes");
const MANIFEST = path.join(__dirname, "wiki_manifest.json");
const FORCE = process.argv.includes("--force");
const DELAY_MS = 900;
const API = "https://en.wikipedia.org/w/api.php";

/** Article titles that differ from the dish name in the app. */
const ALIASES = {
  manti: ["Manti (dumpling)"],
  "turkish-lahmacun": ["Lahmacun"],
  "ci-kofte": ["Çiğ köfte"],
  "socuklu-yumurta": ["Sucuklu yumurta"],
  "sucuk-tava": ["Sucuk"],
  "doner-kebab": ["Döner"],
  "adana-kebab": ["Adana kebabı"],
  kasarli: ["Kaşarlı"],
  gozleme: ["Gözleme"],
  pide: ["Pide"],
  pide2: [],
  "cig-koz": ["Turkish coffee"],
  "turk-kahvesi": ["Turkish coffee"],
  atay: ["Mint tea"],
  "cay": ["Black tea"],
  ayran: ["Ayran"],
  limonata: ["Turkish lemon"],
  "soguk-salgam": ["Salgam şalgamı"],
  maron: ["Hot chocolate"],
  salep: ["Salep"],
  cacik: ["Cacık"],
  cacik2: ["Cacık"],
  "buzlu-cacik": ["Cacık"],
  haydari: ["Haydari"],
  "basbousa": ["Basbousa"],
  knafeh: ["Knafeh"],
  "halawet-el-jibn": ["Kadayıf"],
  kadayif: ["Kadayıf"],
  mahalabiya: ["Mahalabiya"],
  lokum: ["Lokum"],
  "omer-ali": ["Om ali"],
  "om-ali": ["Om ali"],
  "rice-pudding": ["Rice pudding"],
  kahwa: ["Arabic coffee"],
  "kahwa-arabic": ["Arabic coffee"],
  "rose-sharbat": ["Sharbat"],
  labneh: ["Labneh"],
  hummus: ["Hummus"],
  "baba-ghanoush": ["Baba ghanoush"],
  tabbouleh: ["Tabbouleh"],
  fattoush: ["Fattoush"],
  muhammara: ["Muhammara"],
  kebab: ["Kebab"],
  "kebab-plates": ["Kebab"],
  baklava: ["Baklava"],
  "kadin-firini": ["Kadın fırını"],
  mantarlar: ["Mantar"],
  "etli-mercimek": ["Mercimek çorbası"],
  "mercimek-corbasi": ["Mercimek çorbası"],
  "yayla-corbasi": ["Yayla çorbası"],
  "tavuk-suyu-corbasi": ["Tavuk suyu"],
  "sebze-corbasi": ["Sebze çorbası"],
  "kumpir": ["Kumpir"],
  "balik-ekmek": ["Balık ekmek"],
  "cikolatali-yulaf": ["Porridge"],
  "tulum-ahi": ["Halloumi"],
  "kumpir2": [],
  "ispanakli-yogurt": ["Tzatziki"],
  "koz-macun-sos": ["Tomato sauce"],
  "mercimek-ezmesi": ["Lentil soup"],
  "bulgur-pilafi": ["Bulgur"],
  "pirin-pilafi": ["Pilaf"],
  "tavuk-pilav": ["Pilaf"],
  "kavut": ["Kavut"],
  "sari-kilimcik": [],
  "kirmizi-cikolata": ["Chocolate"],

  // Second pass: articles filed under a different name than the dish.
  "banana-pancakes": ["Pancake"],
  "mushroom-risotto": ["Risotto"],
  "roasted-veg-frittata": ["Frittata"],
  "sheet-pan-chicken": ["Roast chicken"],
  "lamb-tagine": ["Tagine"],
  "warak-enab": ["Dolma", "Stuffed grape leaves"],
  "kibbeh-fried": ["Kibbeh"],
  "kibbeh-nayyeh": ["Kibbeh"],
  pastilla: ["Pastilla"],
  arayes: ["Arayes"],
  "zaatar-manakish": ["Manakish", "Za’atar"],
  "cheese-rakakat": ["Sigara böreği", "Cheese pastry"],
  tashreeb: ["Tashreeb"],
  mahalabiya: ["Mahalabiya"],
  "riz-bi-haleeb": ["Rice pudding"],
  atay: ["Herbal tea", "Tea"],
  karak: ["Karak", "Gulf Arabic coffee"],
  pirzola: ["Lamb chop"],
  "kasarli-beyti": ["Iskender kebab"],
  "kuzu-tavuk": ["Stew"],
  "kofte-yemek": ["Köfte"],
  "tavuk-yemek": ["Chicken stew"],
  "patatesli-kofte": ["Köfte"],
  "kiyma-soslu-makarna": ["Spaghetti bolognese"],
  "koy-etesi-kavurma": ["Beef stew"],
  "tavuk-kesmete": ["Kesme"],
  "lezzetli-tavuk": ["Roast chicken"],
  "tavuk-saci": ["Chicken shish"],
  cipura: ["Fried chicken"],
  "patliyan-salatasi": ["Eggplant salad", "Aubergine"],
  "enginar-dolmasi": ["Dolma"],
  "kiymali-pide": ["Pide"],
  kavut: ["Bulgar wheat"],
  ezme: ["Ezme"],
  "sucuklu-yumurta": ["Scrambled eggs"],
  "kavrulmus-biper-salatasi": ["Roasted pepper"],
  "kavrulmus-biber-salatasi": ["Roasted pepper"],
  "sulu-kofte": ["Sulu köfte"],
  "firin-sebze": ["Roasted vegetables"],
  "patlican-tava": ["Eggplant"],
  "eristeli-corbasi": ["Erişte"],
  "tavuk-suyu-corbasi": ["Chicken soup"],
  "sebze-corbasi": ["Vegetable soup"],
  "patates-salatasi": ["Potato salad"],
  "sarisikli-yogurt": ["Tzatziki"],
  "patates-kizartma": ["French fries"],
  "kahvalti-tabagi": ["Turkish breakfast"],
  "kaymakli-kahvalti": ["Smen", "Kaymak"],
  "makarna-salatasi": ["Pasta salad"],
  "lahana-salatasi": ["Coleslaw"],
  "firin-sutlac": ["Rice pudding", "Sütlaç"],
  sutlac: ["Rice pudding", "Sütlaç"],
  "tavuk-gogsu": ["Mastic", "Rice pudding"],
  "halka-tatli": ["Simit", "Halka"],
  "sicak-badem": ["Almond"],
  "irmak-halebi": ["Semolina"],
  "kabak-tatlisi": ["Kabak tatlısı", "Pumpkin pie"],
  fesleme: ["Ice cream"],
  "tahinli-helva": ["Halva"],
  "hurma-tatli": ["Date palm fruit"],
  limonata: ["Lemonade"],
  "soguk-salgam": ["Salgam şalgamı", "Beetroot"],
  "ci-koz": ["Turkish coffee", "Coffee"],
  "brik-a-tuna": ["Brik", "Borek"],
  "kelem-dolmasi": ["Kale dolması", "Dolma"],
  "jalfouti": ["Jalfouti"],
  mashuai: ["Mashuai"],
  "jareesh": ["Jareesh"],
  kabsa: ["Kabsa"],
  "kadin-firini": ["Kadın fırını"],
  "aish-el-saraya": ["Bread pudding"],
  "ashta-bark": ["Kataifi"],
  "tavap-kebabi": ["Kebab"],
  "tavuk-butunesme": ["Döner"],
  "kabak-cipsli-tavuk": ["Roast chicken"],
  "cacik-buzunu": ["Cacık"],
  "hurma-olucu": ["Yogurt"],
  "soganli-yumurtalama": ["Scrambled eggs"],
  "basbousa": ["Basbousa", "Semolina"],
  "napoleon-pastry": ["Napoleon"],
  "lemon-mint-cooler": ["Mint tea"],
  "rose-sharbat": ["Sharbat"],
  salep: ["Salep"],
  "cikolatali-yulaf": ["Porridge"],
  "tulum-ahi": ["Halloumi"],
  "biber-salatasi": ["Roasted pepper"],
  "mercimek-salatasi": ["Lentil"],
  "karnabahar-turisi": ["Pickling"],
  "biber-turisi": ["Pickled pepper"],

  // Third pass, only where the substitute is the same food rather than a
  // generic ingredient. A photo of pide for kıymalı pide is fair; a photo of
  // plain rice for kabsa would not be.
  "cheese-rakakat": ["Börek"],
  "kiymali-pide": ["Pide", "Flatbread"],
  "kadin-firini": ["Baklava"],
  "soguk-salgam": ["Beetroot", "Salgam"],
  "sicak-badem": ["Almonds", "Nuts"],
  "hurma-tatli": ["Date palm", "Dates"],
  "mahalabiya": ["Milk pudding", "Mastet"],
  "eristeli-corbasi": ["Noodle soup", "Vermicelli"],
  "kavrulmus-biber-salatasi": ["Bell pepper"],
  "soganli-yumurtalama": ["Eggs"],
  "sucuklu-yumurta": ["Eggs", "Sucuk"],
  "firin-sebze": ["Vegetable"],
  "tavuk-saci": ["Skewer", "Kebab"],
  "kabak-cipsli-tavuk": ["Chicken"],
  "ezme": ["Meze"],
  "jalfouti": ["Machboos"],
  "mashuai": ["Moroccan cuisine"],
};

// The Pakistani collection has its own alias table; it is long enough to live
// in its own file rather than burying the rest of this script.
const EXTRA_ALIASES = [
  "aliases_pakistani.json",
  "aliases_kebab.json",
  "aliases_dessert.json",
  "aliases_dessert2.json",
  "aliases_final.json",
];
for (const file of EXTRA_ALIASES) {
  const full = path.join(__dirname, file);
  if (fs.existsSync(full)) {
    Object.assign(ALIASES, JSON.parse(fs.readFileSync(full, "utf8")));
  }
}

// Recipes whose Wikipedia lead image is not the dish, found by reviewing
// contact sheets of everything that was downloaded. They are skipped forever,
// so purging a bad photo does not just get undone by the next run.
const DENIED = new Set(
  Object.keys(
    JSON.parse(fs.readFileSync(path.join(__dirname, "denied_photos.json"), "utf8"))
  ).filter((k) => !k.startsWith("_"))
);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Writes the credits file: Wikipedia images are licensed and must be credited. */
function writeCredits(manifest) {
  const lines = [
    "# Recipe photo credits",
    "",
    "Photographs used by the bundled library recipes, with the author and licence",
    "recorded by the Wikipedia API when the image was downloaded.",
    "",
    "Images whose recipe id is missing from this file came from TheMealDB,",
    "whose free API does not require per-image attribution.",
    "",
  ];
  for (const [id, meta] of Object.entries(manifest).sort()) {
    lines.push(`- \`${id}\` — ${meta.artist} · ${meta.licence} · ${meta.title}`);
  }
  fs.writeFileSync(path.join(__dirname, "PHOTO_CREDITS.md"), lines.join("\n"));
}

function request(url, binary) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      {
        headers: {
          "User-Agent": "CookSmart/1.0 (recipe app; local project)",
          "Accept": binary ? "image/*" : "application/json",
        },
      },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          return resolve(request(res.headers.location, binary));
        }
        if (res.statusCode === 429) {
          res.resume();
          return reject(new Error("rate limited"));
        }
        if (res.statusCode !== 200) {
          res.resume();
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () =>
          resolve(binary ? Buffer.concat(chunks) : Buffer.concat(chunks).toString("utf8"))
        );
      }
    );
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error("timeout"));
    });
    req.on("error", reject);
  });
}

/** Asks the API for an article's lead image plus its licence and author. */
async function leadImage(title) {
  const url =
    `${API}?action=query&format=json&redirects=1&prop=pageimages|extmetadata` +
    `&piprop=thumbnail&pithumbsize=1000&titles=${encodeURIComponent(title)}`;
  const data = JSON.parse(await request(url, false));
  const page = Object.values(data.query.pages)[0];
  if (!page || page.missing !== undefined || !page.thumbnail) return null;
  const meta = page.extmetadata || {};
  return {
    src: page.thumbnail.source,
    artist: (meta.Artist && meta.Artist.value || "").replace(/<[^>]+>/g, "").trim(),
    licence: (meta.LicenseShortName && meta.LicenseShortName.value || "").trim(),
    page: `https://en.wikipedia.org/wiki/${encodeURIComponent(page.title)}`,
    width: page.thumbnail.width,
  };
}

async function withRetry(fn, attempts = 3) {
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (err) {
      if (i === attempts - 1) return null;
      await sleep(4000 * (i + 1));
    }
  }
  return null;
}

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

/** Returns the distinctive words of a dish name, least generic first. */
function keyWords(name) {
  return norm(name)
    .split(" ")
    .filter((t) => t.length > 2);
}

/**
 * Looks for an article about this dish by search.
 *
 * Search results are only accepted when the article title actually contains a
 * distinctive word from the recipe name, so "Chicken Tacos" can pick up "Taco"
 * but a recipe for tea can never pick up some unrelated article that happened
 * to mention the word.
 */
async function searchLeadImage(name) {
  const url = `${API}?action=query&format=json&list=search&srlimit=6&srsearch=${encodeURIComponent(name)}`;
  const data = JSON.parse(await request(url, false));
  const results = (data.query && data.query.search) || [];
  const words = keyWords(name);
  if (!words.length) return null;

  for (const hit of results) {
    const title = norm(hit.title);
    const wordsInTitle = new Set(title.split(" "));
    if (!words.some((w) => wordsInTitle.has(w))) continue;
    const info = await withRetry(() => leadImage(hit.title));
    if (info) return { ...info, matched: hit.title };
    await sleep(DELAY_MS);
  }
  return null;
}

function readRecipes() {
  const dir = path.join(ROOT, "lib", "data");
  const out = [];
  for (const file of fs.readdirSync(dir).filter((f) => f.endsWith(".dart"))) {
    const text = fs.readFileSync(path.join(dir, file), "utf8");
    const rx = /id: '([^']+)',\s*(?:imageAsset: '[^']*',\s*)?name: '([^']+)'/g;
    let m;
    while ((m = rx.exec(text)) !== null) out.push({ id: m[1], name: m[2] });
  }
  return out;
}

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const recipes = readRecipes();
  const manifest = fs.existsSync(MANIFEST) ? JSON.parse(fs.readFileSync(MANIFEST, "utf8")) : {};

  let downloaded = 0;
  const noSource = [];

  for (const recipe of recipes) {
    if (DENIED.has(recipe.id)) continue;
    if (!FORCE && manifest[recipe.id]) continue;
    const file = path.join(OUT_DIR, `${recipe.id}.jpg`);
    const hasFile = !FORCE && fs.existsSync(file) && fs.statSync(file).size > 5000;

    const candidates = [...(ALIASES[recipe.id] || []), recipe.name];
    let info = null;
    for (const title of candidates) {
      info = await withRetry(() => leadImage(title));
      if (info) break;
      await sleep(DELAY_MS);
    }
    // The article may simply be filed under another name, so search for it too.
    if (!info) {
      info = await withRetry(() => searchLeadImage(recipe.name));
      if (info) {
        await sleep(DELAY_MS);
      }
    }
    if (!info) {
      noSource.push(`${recipe.id} (${recipe.name})`);
      await sleep(DELAY_MS);
      continue;
    }

    if (!hasFile) {
      const bytes = await withRetry(() => request(info.src, true));
      if (!bytes || bytes.length < 5000) {
        noSource.push(`${recipe.id} (${recipe.name}) - download failed`);
        await sleep(DELAY_MS);
        continue;
      }
      fs.writeFileSync(file, bytes);
      downloaded++;
    }
    manifest[recipe.id] = {
      source: "Wikipedia",
      title: info.page,
      artist: info.artist || "see file page",
      licence: info.licence || "see file page",
    };
    // Written every time, because this run takes minutes and may be cut short.
    // Losing the credits would mean shipping unattributed images.
    fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 1));
    process.stdout.write(".");
    await sleep(DELAY_MS);
  }

  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 1));
  writeCredits(manifest);

  console.log(`\n${downloaded} new downloads, ${Object.keys(manifest).length} recipes with a photo`);
  if (noSource.length) {
    console.log(`\nNo Wikipedia image for ${noSource.length}:`);
    noSource.forEach((n) => console.log(`  ${n}`));
  }
})();
