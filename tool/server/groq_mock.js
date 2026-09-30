/**
 * Offline stand-in for groq_proxy.js.
 *
 * Serves the exact same three endpoints so the whole CookSmart flow — live
 * recipe generation, dish suggestions, photo loading and image caching — can be
 * exercised without a Groq key or any API credits. Swap the app's endpoint to
 * groq_proxy.js when you want real Groq output.
 *
 *   node tool/server/groq_mock.js [--port 8788]
 */
const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const PORT = Number(argValue("--port") || process.env.PORT || 8788);
const CACHE = path.join(__dirname, ".image-cache");
const LATENCY = Number(process.env.MOCK_LATENCY || 700);

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

/* ------------------------------------------------------------------ */
/* Deterministic recipe composition                                     */
/* ------------------------------------------------------------------ */

const PAN = {
  garlic: "2 cloves, minced",
  onion: "1, sliced",
  "olive oil": "2 tbsp",
  butter: "1 tbsp",
  salt: "to taste",
  pepper: "to taste",
  lemon: "1/2, juiced",
  "chili flakes": "1 pinch",
  "soy sauce": "2 tbsp",
  egg: "2, beaten",
  eggs: "2, beaten",
  milk: "150 ml",
  flour: "150 g",
  cheese: "50 g, grated",
  rice: "2 cups, cooked",
  pasta: "200 g",
  potato: "300 g, diced",
  tomato: "2, chopped",
  "bell pepper": "1, sliced",
  onion_: "1, sliced",
  spinach: "2 handfuls",
  mushroom: "250 g, sliced",
  chicken: "400 g, cubed",
  shrimp: "250 g, peeled",
  beans: "1 can, drained",
  corn: "150 g",
  carrot: "1, diced",
  ginger: "1 thumb, grated",
  honey: "1 tbsp",
  peanut_butter: "3 tbsp",
  lime: "1",
  lemon_: "1",
  pasta_: "200 g",
  stock: "500 ml",
  cream: "100 ml",
  parmesan: "40 g",
  cumin: "1 tsp",
  paprika: "2 tsp",
  "hot sauce": "to serve",
  "chocolate": "120 g",
  "dark chocolate": "120 g",
  sugar: "50 g",
  coconut_milk: "400 ml",
  curry_powder: "2 tbsp",
  tofu: "300 g, cubed",
  "spring onion": "3, sliced",
  basil: "a handful",
  tortilla: "4",
  "black beans": "1 can, drained",
  noodles: "200 g",
  cucumber: "1/2, julienned",
  avocado: "1",
  oats: "1 cup",
  banana: "1, sliced",
  "baking powder": "1 tsp",
  "sesame oil": "1 tsp",
  "vegetable stock": "900 ml",
  "peanut butter": "3 tbsp",
};

const QTY = (n) => PAN[n] || `${Math.round(60 + ((n.length * 37) % 240))} g`;

/* Kilocalories for the portion QTY() hands out, so the mock carries the same
   nutrition shape as the real endpoint. */
const KCAL = {
  garlic: 14,
  onion: 60,
  "olive oil": 240,
  butter: 200,
  salt: 0,
  pepper: 5,
  lemon: 9,
  lime: 20,
  "chili flakes": 4,
  "soy sauce": 18,
  egg: 72,
  eggs: 216,
  milk: 110,
  flour: 364,
  cheese: 200,
  rice: 215,
  pasta: 350,
  potato: 160,
  tomato: 36,
  "bell pepper": 25,
  spinach: 12,
  mushroom: 66,
  chicken: 240,
  shrimp: 100,
  beans: 200,
  "black beans": 220,
  corn: 130,
  carrot: 33,
  ginger: 12,
  honey: 70,
  "peanut butter": 280,
  stock: 15,
  "vegetable stock": 15,
  cream: 340,
  parmesan: 200,
  cumin: 8,
  paprika: 15,
  "hot sauce": 5,
  chocolate: 550,
  "dark chocolate": 600,
  sugar: 195,
  "coconut milk": 220,
  "curry powder": 30,
  tofu: 180,
  "spring onion": 10,
  basil: 3,
  tortilla: 150,
  noodles: 350,
  cucumber: 20,
  avocado: 240,
  oats: 190,
  banana: 130,
  "baking powder": 0,
  "sesame oil": 45,
};

const kcalFor = (n) => KCAL[n] ?? 90;

const STYLE = {
  egg: "skillet",
  eggs: "skillet",
  rice: "wok",
  noodles: "wok",
  pasta: "pot",
  shrimp: "pan",
  chicken: "roasting tray",
  tofu: "wok",
  potato: "roasting tray",
  mushroom: "pan",
  beans: "pot",
  "black beans": "pot",
  corn: "pan",
  spinach: "pot",
  chocolate: "bowl",
  "dark chocolate": "bowl",
  banana: "bowl",
  oats: "pot",
};

const NAME_BITS = {
  garlic: "Garlic",
  lemon: "Lemon",
  lime: "Lime",
  ginger: "Ginger",
  chili: "Chilli",
  honey: "Honey",
  butter: "Butter",
  cheese: "Cheese",
  tomato: "Tomato",
  mushroom: "Mushroom",
  spinach: "Spinach",
  carrot: "Carrot",
  peanut: "Peanut",
  coconut: "Coconut",
  curry: "Curry",
  basil: "Basil",
  pepper: "Pepper",
};

const SURNAMES = [
  "Skillet", "Stir-Fry", "One-Pan", "Rush", "Skillet Surprise", "Sheet-Pan",
  "Comfort Bowl", "Sauce", "Fry", "Pilaf", "Risotto", "Curry", "Slurry",
];
const SOURCES = ["mock-server", "test-double"];

const EMOJI = ["🍝", "🍜", "🥘", "🍛", "🍲", "🥗", "🍳", "🥙", "🌮", "🍚", "🥟"];
const pick = (arr, seed) => arr[Math.abs(seed) % arr.length];
const hash = (s) => {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return h;
};

function composeRecipe(rawList, servings, dish) {
  const list = rawList.map((s) => String(s).trim().toLowerCase()).filter(Boolean);
  if (!list.length && !dish) {
    const err = new Error("ingredients or a dish name are required");
    err.status = 400;
    throw err;
  }
  const seed = hash(list.join(",") + (dish || ""));
  const hero = list.isNotEmpty ? list[0] : (dish || "Chef's pick");
  const style = STYLE[hero] || STYLE[list.find((i) => STYLE[i])] || "pan";

  const qualifiers = list
    .filter((i) => NAME_BITS[i.split(" ")[0]])
    .map((i) => NAME_BITS[i.split(" ")[0]])
    .slice(0, 2);

  const name = dish
    ? String(dish)
    : (qualifiers.length ? qualifiers.join(" & ") : hero[0].toUpperCase() + hero.slice(1)) +
      " " + pick(SURNAMES, seed);

  const owned = list.slice();
  const extras = ["salt", "olive oil"].filter((e) => !owned.includes(e));
  const missing = extras;

  const ingredientNames = [...owned, ...extras];
  const minutes = 12 + (Math.abs(seed) % 34);
  const difficulty = minutes < 20 ? "Easy" : minutes < 35 ? "Easy" : "Medium";
  const servingsOut = Number(servings) || 2;
  const ingredients = ingredientNames.map((i) => ({
    name: i,
    quantity: QTY(i),
    calories: kcalFor(i),
  }));
  const totalCalories = ingredients.reduce((sum, i) => sum + i.calories, 0);

  return {
    name,
    description:
      `A ${minutes}-minute ${style} dish built around ${list.slice(0, 3).join(", ")}. ` +
      `Everything happens in one pan, so it is weeknight friendly.`,
    timeMinutes: minutes,
    difficulty,
    servings: servingsOut,
    emoji: pick(EMOJI, seed),
    imagePrompt: `${name}, ${list.join(" and ")}, dark moody food photography`,
    owned,
    missing,
    calories: totalCalories,
    caloriesPerServing: Math.round(totalCalories / servingsOut),
    ingredients,
    steps: [
      `Heat the ${style} until hot, then add the oil and let it shimmer.`,
      `Add ${list.slice(0, 2).join(" and ")} and cook for 3 minutes until they take on colour.`,
      `Stir in the remaining ingredients and season with salt and pepper.`,
      `Cover and cook for ${Math.max(4, minutes - 8)} minutes, then uncover to reduce.`,
      `Taste, adjust the seasoning, and serve straight from the pan.`,
    ],
    source: "groq",
  };
}

const DISH_POOL = [
  "Charred Corn Tacos", "Miso Butter Ramen", "Saffron Seafood Paella", "Smoked Brisket Chili",
  "Coconut Lemongrass Curry", "Blistered Tomato Orecchiette", "Ginger Scallion Dumplings",
  "Harissa Roast Cauliflower", "Sesame Soba Salad", "Brown Butter Banana Bread",
  "Tamarind Chickpea Curry", "Gochujang Glazed Ribs", "Preserved Lemon Tagine",
  "Chili Crisp Cucumber Salad", "Za'atar Flatbread", "Miso Eggplant Bento",
  "Sichuan Dry Green Beans", "Cardamom Rice Pudding", "Crispy Rice Salad", "Miso Mushroom Pasta",
];

function suggest(query, count) {
  const n = Math.min(Math.max(Number(count) || 6, 1), 12);
  const q = String(query || "").toLowerCase().trim();
  if (q) {
    return {
      names: DISH_POOL.filter((d) => d.toLowerCase().includes(q)).slice(0, n),
      source: "groq",
    };
  }
  const seed = hash(String(Date.now() / 1000 | 0));
  const pool = [...DISH_POOL];
  const out = [];
  for (let i = 0; i < n && pool.length; i++) {
    out.push(pool.splice(Math.abs(seed + i * 7) % pool.length, 1)[0]);
  }
  return { names: out, source: "groq" };
}

/* ------------------------------------------------------------------ */
/* Images                                                               */
/*                                                                     */
/* Order of preference: a real photo of a real dish (TheMealDB), then    */
/* any real photograph (picsum), then a generated gradient so the app    */
/* still gets a decodable image on a fully offline machine.              */
/* ------------------------------------------------------------------ */

const STOP_WORDS = new Set([
  "and", "the", "with", "for", "from", "food", "photography", "photo", "editorial",
  "natural", "window", "light", "shallow", "depth", "field", "dark", "moody",
  "background", "text", "watermark", "style", "a", "an", "of", "in", "on", "to",
  "cooked", "home", "plate", "bowl", "pan", "skillet", "wok", "roasting", "tray",
  "recipe", "dish", "quick", "minute", "minutes",
]);

function keywords(prompt) {
  return String(prompt || "")
    .toLowerCase()
    .replace(/[^a-z\s]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 2 && !STOP_WORDS.has(w));
}

function httpGet(url, depth = 0) {
  return new Promise((resolve) => {
    if (depth > 4) return resolve(null);
    const client = url.startsWith("http:") ? http : https;
    const req = client.get(url, { headers: { "User-Agent": "cooksmart-mock/1.0" } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        const next = new URL(res.headers.location, url).toString();
        return resolve(httpGet(next, depth + 1));
      }
      if (res.statusCode !== 200) {
        res.resume();
        return resolve(null);
      }
      const chunks = [];
      res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve(Buffer.concat(chunks)));
    });
    req.setTimeout(9000, () => {
      req.destroy();
      resolve(null);
    });
    req.on("error", () => resolve(null));
  });
}

/** Looks up a real photograph of a real dish on the public TheMealDB test API. */
async function mealDbThumb(query) {
  const raw = await httpGet(
    `https://www.themealdb.com/api/json/v1/1/search.php?s=${encodeURIComponent(query)}`
  );
  if (!raw) return null;
  try {
    const meals = JSON.parse(raw.toString("utf8")).meals;
    if (!meals || !meals.length) return null;
    return meals[0].strMealThumb || null;
  } catch (_) {
    return null;
  }
}

function cacheFile(seed) {
  return path.join(CACHE, `mock-${seed.replace(/[^a-z0-9]+/gi, "_").slice(0, 60)}.jpg`);
}

async function imageFor(prompt) {
  fs.mkdirSync(CACHE, { recursive: true });

  // 1. A real photo of a real dish, when TheMealDB knows the name.
  for (const word of keywords(prompt).slice(0, 3)) {
    const thumb = await mealDbThumb(word);
    if (thumb) return { url: thumb, source: "groq", provider: "themealdb" };
  }

  // 2. Any real photograph, seeded so a dish always gets the same one.
  const file = cacheFile(prompt);
  if (fs.existsSync(file)) {
    return { url: `/image/${path.basename(file)}`, file, source: "groq", provider: "picsum" };
  }
  const photo = await httpGet(`https://picsum.photos/seed/${encodeURIComponent(prompt)}/1024/576`);
  if (photo && photo.length > 2000) {
    fs.writeFileSync(file, photo);
    return { url: `/image/${path.basename(file)}`, file, source: "groq", provider: "picsum" };
  }

  // 3. Generated gradient, so the app always receives a decodable image.
  const png = gradientPng(1024, 576, [226, 104, 26]);
  const pngFile = file.replace(/\.jpg$/, ".png");
  fs.writeFileSync(pngFile, png);
  return { url: `/image/${path.basename(pngFile)}`, file: pngFile, source: "groq", provider: "generated" };
}

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      crcTable[n] = c;
    }
  }
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  return crc ^ 0xffffffff;
}

/** Minimal PNG writer, used when no photo source is reachable. */
function gradientPng(w, h, rgb) {
  const raw = Buffer.alloc((w * 3 + 1) * h);
  let p = 0;
  for (let y = 0; y < h; y++) {
    raw[p++] = 0;
    for (let x = 0; x < w; x++) {
      const t = (x / w) * 0.6 + (y / h) * 0.4;
      raw[p++] = Math.round(18 + t * (rgb[0] - 18));
      raw[p++] = Math.round(14 + t * (rgb[1] - 14));
      raw[p++] = Math.round(11 + t * (rgb[2] - 11));
    }
  }
  const chunk = (type, data) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(body) >>> 0);
    return Buffer.concat([len, body, crc]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw)),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

/* ------------------------------------------------------------------ */
/* Server                                                              */
/* ------------------------------------------------------------------ */

const MIME = { ".jpg": "image/jpeg", ".png": "image/png" };

const server = http.createServer((req, res) => {
  const url = req.url.split("?")[0];

  if (url.startsWith("/image/")) {
    const file = path.join(CACHE, path.basename(url));
    if (!fs.existsSync(file)) {
      res.writeHead(404);
      return res.end();
    }
    res.writeHead(200, { "Content-Type": MIME[path.extname(file)] || "application/octet-stream" });
    return fs.createReadStream(file).pipe(res);
  }

  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    });
    return res.end();
  }

  let raw = "";
  req.on("data", (c) => (raw += c));
  req.on("end", async () => {
    const started = Date.now();
    res.setHeader("Access-Control-Allow-Origin", "*");
    let body = {};
    try {
      body = raw ? JSON.parse(raw) : {};
    } catch (_) {
      res.writeHead(400, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "body must be JSON" }));
    }
    try {
      let data;
      if (url === "/gemini/recipe") {
        data = composeRecipe(body.ingredients || [], body.servings, body.dish);
      } else if (url === "/gemini/suggest") data = suggest(body.query, body.count);
      else if (url === "/gemini/image") data = await imageFor(String(body.prompt || "dish"));
      else {
        res.writeHead(404, { "Content-Type": "application/json" });
        return res.end(JSON.stringify({ error: "unknown endpoint" }));
      }
      console.log(`  ✓ ${url} (${Date.now() - started}ms) [mock]`);
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify(data));
    } catch (err) {
      res.writeHead(err.status || 500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: err.message }));
    }
  });
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`CookSmart mock Groq API on http://127.0.0.1:${PORT}  (no key needed)`);
    console.log(`  emulator: http://10.0.2.2:${PORT}`);
    console.log(`  source   : ${SOURCES.join(" + ")}`);
  });
}

module.exports = { server, composeRecipe, suggest, imageFor, gradientPng };
