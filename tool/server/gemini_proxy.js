/**
 * CookSmart ↔ Gemini proxy.
 *
 * The Gemini key stays in this process (GEMINI_API_KEY) and is never shipped in
 * the Flutter app, where anyone could extract it from the APK. The app calls
 * these three small endpoints instead of Google directly:
 *
 *   POST /gemini/recipe    { ingredients: string[], servings?: number, dish?: string }
 *   POST /gemini/suggest   { query?: string, count?: number }
 *   POST /gemini/image     { prompt: string, dish?: string }
 *
 * The photo route does not use Gemini: image generation is billed per image, so
 * a real food photograph is looked up from TheMealDB's free API instead, with a
 * generated gradient as a last resort.
 *
 * Usage:  $env:GEMINI_API_KEY = "AIza..."   # PowerShell
 *         node tool/server/gemini_proxy.js [--port 8787]
 */
const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const PORT = Number(argValue("--port") || process.env.PORT || 8787);
const GEMINI_BASE =
  process.env.GEMINI_BASE_URL || "https://generativelanguage.googleapis.com/v1beta";
/**
 * Models to try, in order. The free tier sheds load unevenly between them, so a
 * model that is saturated for one request often answers the next. A model that
 * is retired outright answers 404, which is not retryable, so it is skipped.
 */
const MODELS = (
  process.env.GEMINI_MODELS || process.env.GEMINI_MODEL || "gemini-3.8-flash,gemini-3-flash-preview,gemini-flash-latest"
)
  .split(",")
  .map((m) => m.trim())
  .filter(Boolean);
const CACHE = process.env.CACHE_DIR || path.join(__dirname, ".image-cache");
const MEALDB = "https://www.themealdb.com/api/json/v1/1";
const MAX_TOKENS = Number(process.env.GEMINI_MAX_TOKENS || 4000);

const EMOJI = ["🍝", "🍜", "🥘", "🍛", "🍲", "🥗", "🍳", "🥙", "🌮", "🍚", "🥟", "🍱"];

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

/* ------------------------------------------------------------------ */
/* Gemini transport                                                    */
/* ------------------------------------------------------------------ */

/**
 * Calls generateContent. `responseMimeType: application/json` makes the model
 * answer with parseable JSON, which removes the need for prompt gymnastics.
 */
function callGemini(system, user, model) {
  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    const err = new Error("GEMINI_API_KEY is not set on the proxy");
    err.status = 503;
    throw err;
  }

  const body = JSON.stringify({
    systemInstruction: { parts: [{ text: system }] },
    contents: [{ role: "user", parts: [{ text: user }] }],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: MAX_TOKENS,
      responseMimeType: "application/json",
    },
  });

  const url = new URL(`${GEMINI_BASE}/models/${encodeURIComponent(model)}:generateContent`);
  url.searchParams.set("key", key);

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        method: "POST",
        hostname: url.hostname,
        path: url.pathname + url.search,
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
        },
        timeout: 120000,
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          let parsed;
          try {
            parsed = JSON.parse(raw);
          } catch (_) {
            parsed = null;
          }
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
            return;
          }
          const message =
            (parsed &&
              parsed.error &&
              parsed.error.message) ||
            `Gemini HTTP ${res.statusCode}`;
          const err = new Error(message);
          err.status = res.statusCode;
          // The API sheds load with transient 429s and 503s. Retrying briefly
          // turns a spiky error into a slightly slower answer, which is a far
          // better outcome for someone waiting on a recipe.
          if (RETRYABLE.has(res.statusCode)) err.retryable = true;
          // It also says how long to wait, so use that rather than guessing.
          const hint = /retry in ([\d.]+)\s*s/i.exec(message);
          if (hint) err.retryAfterMs = Math.ceil(Number(hint[1]) * 1000);
          reject(err);
        });
      }
    );
    req.on("timeout", () => req.destroy(new Error("Gemini request timed out")));
    req.on("error", (e) => {
      e.retryable = true;
      reject(e);
    });
    req.write(body);
    req.end();
  });
}

/** Statuses worth retrying: load shedding and short network blips. */
const RETRYABLE = new Set([408, 429, 500, 502, 503, 504]);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Pulls the first JSON object out of a model reply, ignoring code fences. */
function extractJson(text) {
  const cleaned = String(text || "")
    .replace(/```json/gi, "")
    .replace(/```/g, "")
    .trim();
  const start = cleaned.indexOf("{");
  if (start === -1) throw new Error("model reply contained no JSON object");
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = start; i < cleaned.length; i++) {
    const ch = cleaned[i];
    if (inString) {
      if (escaped) escaped = false;
      else if (ch === "\\") escaped = true;
      else if (ch === '"') inString = false;
      continue;
    }
    if (ch === '"') inString = true;
    else if (ch === "{") depth++;
    else if (ch === "}") {
      depth--;
      if (depth === 0) return JSON.parse(cleaned.slice(start, i + 1));
    }
  }
  throw new Error("model reply contained a truncated JSON object");
}

/**
 * Calls the first model that answers. Load shedding is per-model on the free
 * tier, so falling through the list turns a hard failure into a slower answer.
 */
async function callAnyModel(system, user) {
  let lastError;
  for (const model of MODELS) {
    try {
      return await callGemini(system, user, model);
    } catch (err) {
      lastError = err;
      // A retired or unknown model will not start working on a retry, but a
      // saturated one might, so only the former moves straight on.
      if (err.status === 404 || err.status === 400) {
        console.log(`  model ${model} unavailable, trying the next one`);
        continue;
      }
      throw err;
    }
  }
  throw lastError;
}

async function askJson(system, user) {
  const reply = await withRetry(() => callAnyModel(system, user));
  const parts =
    reply &&
    reply.candidates &&
    reply.candidates[0] &&
    reply.candidates[0].content &&
    reply.candidates[0].content.parts;
  const text = parts && parts.map((p) => p.text || "").join("");
  if (!text) throw new Error("Gemini returned an empty completion");
  return extractJson(text);
}

/** Retries a call a few times when the API is shedding load. */
async function withRetry(fn, attempts) {
  // A serverless host kills a function that runs too long: Vercel allows 10s on
  // Hobby and 60s on Pro. Retrying blindly on Hobby means every attempt is cut
  // off mid-flight, so the budget has to be sized for the platform.
  const budget = attempts || (process.env.VERCEL ? 2 : 4);
  let lastError;
  for (let i = 0; i < budget; i++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      if (!err.retryable || i === budget - 1) throw err;
      // Obey the wait the API asked for, with jitter so a burst of clients does
      // not retry in lockstep, and a floor so a silly hint cannot spin hot.
  const model = MODELS[0];
  const backoff = 1500 * Math.pow(2, i);
  const wait = Math.max(1500, err.retryAfterMs || backoff) + Math.floor(Math.random() * 800);

      console.log(`  retry ${i + 1}/${budget - 1} in ${wait}ms (${err.message.slice(0, 60)})`);
      await sleep(wait);
    }
  }
  throw lastError;
}

/* ------------------------------------------------------------------ */
/* Domain logic                                                        */
/* ------------------------------------------------------------------ */

const RECIPE_SYSTEM = [
  "You are the head chef inside CookSmart, a recipe app that cooks whatever the user already has.",
  "Reply with ONE JSON object and nothing else. No markdown, no prose, no code fences.",
  "Use plain ASCII characters only. Never use an en dash, an em dash or curly quotes.",
  "Schema:",
  "{",
  '  "name": "string, dish name under 42 chars",',
  '  "description": "string, one or two sentences, appetising, under 180 chars",',
  '  "timeMinutes": number,',
  '  "difficulty": "Easy" | "Medium" | "Hard",',
  '  "servings": number,',
  '  "emoji": "a single food emoji",',
  '  "imagePrompt": "the dish name, used to find a photograph",',
  '  "owned": ["ingredients the user already has, lowercase, from their list only"],',
  '  "missing": ["ingredients they must buy, lowercase"],',
  '  "calories": number,',
  '  "caloriesPerServing": number,',
  '  "ingredients": [{ "name": "lowercase ingredient", "quantity": "e.g. 200 g, 2 tbsp", "calories": number }],',
  '  "steps": ["imperative cooking steps, 5 to 7 of them, each under 220 chars"]',
  "}",
  "Use every ingredient the user listed somewhere in the recipe. Invent sensible extras only",
  "when a dish truly needs them, and put those in missing. Quantities must be realistic.",
  "Calories are kilocalories for the quantity as written, so the calories on every",
  "ingredient line must add up to the total calories you report. Give the per-serving figure too.",
  "Every step must be actionable: name the heat level, the pan or oven temperature, and how long",
  "to cook, so a beginner can follow it without guessing.",
].join("\n");

async function buildRecipe(ingredients, servings, dish) {
  const list = ingredients.map((s) => String(s).trim().toLowerCase()).filter(Boolean);
  if (!list.length && !dish) {
    const err = new Error("ingredients or a dish name are required");
    err.status = 400;
    throw err;
  }

  const brief = [];
  if (list.length) brief.push(`The cook has: ${list.join(", ")}.`);
  if (servings) brief.push(`Cook for ${servings} people.`);
  brief.push(
    dish
      ? `They want to cook "${dish}" - make that the dish, still using everything they have.`
      : "Build the single best recipe for exactly those ingredients.",
  );

  const raw = await askJson(RECIPE_SYSTEM, brief.join("\n"));

  const ingredientsOut = Array.isArray(raw.ingredients) ? raw.ingredients : [];
  const steps = Array.isArray(raw.steps) ? raw.steps : [];
  if (!ingredientsOut.length || !steps.length) {
    throw new Error("model returned an incomplete recipe");
  }

  const lower = (s) => String(s).trim().toLowerCase();
  const owned = (Array.isArray(raw.owned) ? raw.owned : list).map(lower);
  const ownedSet = new Set(owned);
  const missing = (Array.isArray(raw.missing) ? raw.missing : [])
    .map(lower)
    .filter((m) => !ownedSet.has(m));

  const calories =
    Number.isFinite(Number(raw.calories)) && Number(raw.calories) > 0
      ? Math.round(Number(raw.calories))
      : null;

  return {
    name: String(raw.name || "Chef's Special").slice(0, 60),
    description: String(raw.description || ""),
    timeMinutes: Number(raw.timeMinutes) || 30,
    difficulty: ["Easy", "Medium", "Hard"].includes(raw.difficulty) ? raw.difficulty : "Easy",
    servings: Number(raw.servings) || servings || 2,
    emoji: typeof raw.emoji === "string" && raw.emoji ? raw.emoji : pick(list),
    imagePrompt: String(raw.imagePrompt || raw.name || "a home cooked dish"),
    owned,
    missing,
    calories,
    caloriesPerServing:
      Number.isFinite(Number(raw.caloriesPerServing)) && Number(raw.caloriesPerServing) > 0
        ? Math.round(Number(raw.caloriesPerServing))
        : null,
    ingredients: ingredientsOut.map((i) => ({
      name: lower(i.name || ""),
      quantity: String(i.quantity || "to taste"),
      calories: Number.isFinite(Number(i.calories)) ? Math.round(Number(i.calories)) : null,
    })),
    steps: steps.map((s) => String(s)),
    source: "gemini",
  };
}

const SUGGEST_SYSTEM = [
  "You are the sous chef of CookSmart, suggesting what to cook next.",
  'Reply with ONE JSON object and nothing else, no code fences: { "names": ["dish name", ...] }',
  "Use plain ASCII characters only. Never use an en dash, an em dash or curly quotes.",
  "Rules: give real, appealing, specific dishes from around the world.",
  "No duplicates, no numbering, under 34 characters each.",
].join("\n");

async function suggestDishes(query, count) {
  const n = Math.min(Math.max(Number(count) || 6, 1), 12);
  const raw = await askJson(
    SUGGEST_SYSTEM,
    query
      ? `Suggest ${n} dishes that use or pair with "${query}".`
      : `Suggest ${n} dinner dishes for an adventurous home cook.`,
  );
  const names = (Array.isArray(raw.names) ? raw.names : [])
    .map((s) => String(s).trim())
    .filter(Boolean)
    .slice(0, n);
  if (!names.length) throw new Error("model returned no suggestions");
  return { names, source: "gemini" };
}

const pick = (list) => EMOJI[Math.abs(hash(list.join(","))) % EMOJI.length];
function hash(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0;
  return h;
}

/* ------------------------------------------------------------------ */
/* Food photography                                                    */
/*                                                                     */
/* Gemini image generation is billed per image, so a real photograph is  */
/* looked up on TheMealDB's free API instead. Anything unmatched falls */
/* back to a seeded photograph, then a generated gradient, so the      */
/* route always returns a decodable image.                             */
/* ------------------------------------------------------------------ */

const STOP_WORDS = new Set([
  "a", "an", "and", "with", "in", "on", "of", "the", "for", "to", "from", "dark", "food",
  "photography", "editorial", "natural", "light", "shallow", "depth", "field", "background",
  "no", "text", "watermark", "home", "cooked", "plate", "bowl", "styled", "rustic", "table",
]);

function keywords(text) {
  return String(text || "")
    .replace(/[^a-zA-Z\s-]/g, " ")
    .split(/[\s-]+/)
    .filter((w) => w.length > 2 && !STOP_WORDS.has(w.toLowerCase()));
}

function httpGet(url) {
  return new Promise((resolve) => {
    const req = https.get(url, { timeout: 9000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        res.resume();
        return resolve(httpGet(new URL(res.headers.location, url).toString()));
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

async function mealDbLookup(query) {
  const raw = await httpGet(`${MEALDB}/search.php?s=${encodeURIComponent(query)}`);
  if (!raw) return null;
  try {
    const meals = JSON.parse(raw.toString("utf8")).meals;
    if (meals && meals.length && meals[0].strMealThumb) return meals[0].strMealThumb;
  } catch (_) {
    /* fall through to the next candidate */
  }
  return null;
}

function cacheFile(seed) {
  return path.join(CACHE, `${seed.replace(/[^a-z0-9]+/gi, "_").slice(0, 60)}.jpg`);
}

async function generateImage(prompt, dish) {
  fs.mkdirSync(CACHE, { recursive: true });
  const queries = [dish, prompt, ...keywords(`${dish || ""} ${prompt || ""}`)].filter(Boolean);

  for (const q of queries.slice(0, 4)) {
    const thumb = await mealDbLookup(q);
    if (thumb) return { url: thumb, source: "gemini", provider: "themealdb" };
  }

  const seed = String(dish || prompt || "cooksmart");
  const file = cacheFile(seed);
  if (fs.existsSync(file)) {
    return { url: `/image/${path.basename(file)}`, file, source: "gemini", provider: "picsum" };
  }
  const photo = await httpGet(
    `https://picsum.photos/seed/${encodeURIComponent(seed)}/1024/576`,
  );
  if (photo && photo.length > 2000) {
    fs.writeFileSync(file, photo);
    return { url: `/image/${path.basename(file)}`, file, source: "gemini", provider: "picsum" };
  }

  const png = gradientPng(1024, 576, [226, 104, 26]);
  const pngFile = file.replace(/\.jpg$/, ".png");
  fs.writeFileSync(pngFile, png);
  return {
    url: `/image/${path.basename(pngFile)}`,
    file: pngFile,
    source: "gemini",
    provider: "generated",
  };
}

/* --- minimal PNG encoder for the last-resort gradient ---------------- */

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      crcTable[n] = c >>> 0;
    }
  }
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body), 0);
  return Buffer.concat([len, body, crc]);
}

function gradientPng(w, h, rgb) {
  const raw = Buffer.alloc((w * 3 + 1) * h);
  let p = 0;
  for (let y = 0; y < h; y++) {
    raw[p++] = 0;
    const k = y / h;
    for (let x = 0; x < w; x++) {
      const t = k * 0.8 + (x / w) * 0.2;
      raw[p++] = Math.round(rgb[0] * (1 - t) + 40 * t);
      raw[p++] = Math.round(rgb[1] * (1 - t) + 22 * t);
      raw[p++] = Math.round(rgb[2] * (1 - t) + 12 * t);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}

/* ------------------------------------------------------------------ */
/* HTTP surface                                                        */
/* ------------------------------------------------------------------ */

const ROUTES = {
  "/gemini/recipe": (body) => buildRecipe(body.ingredients || [], body.servings, body.dish),
  "/gemini/suggest": (body) => suggestDishes(body.query, body.count),
  "/gemini/image": (body) =>
    body.prompt || body.dish
      ? generateImage(body.prompt || body.dish, body.dish)
      : Promise.reject(httpError("prompt is required", 400)),
};

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

const server = http.createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  // Health check for the host, and a way to confirm the key is present without
  // spending a call on the API.
  if (req.method === "GET" && req.url.split("?")[0] === "/health") {
    return send(res, 200, {
      ok: true,
      key: Boolean(process.env.GEMINI_API_KEY),
      models: MODELS,
    });
  }

  if (req.method === "GET" && req.url.startsWith("/image/")) {
    const file = path.join(CACHE, path.basename(req.url.split("?")[0]));
    if (fs.existsSync(file)) {
      const ext = path.extname(file).toLowerCase();
      res.writeHead(200, { "Content-Type": ext === ".png" ? "image/png" : "image/jpeg" });
      return res.end(fs.readFileSync(file));
    }
    return send(res, 404, { error: "no such image" });
  }

  let raw = "";
  req.on("data", (c) => {
    raw += c;
    if (raw.length > 1e6) req.destroy();
  });
  req.on("end", async () => {
    const handler = ROUTES[req.url.split("?")[0]];
    if (!handler) return send(res, 404, { error: "unknown endpoint" });
    let body = {};
    try {
      body = raw ? JSON.parse(raw) : {};
    } catch (_) {
      return send(res, 400, { error: "body must be JSON" });
    }
    const started = Date.now();
    try {
      const data = await handler(body);
      console.log(`  ok ${req.url} (${Date.now() - started}ms) [${data.source || "gemini"}]`);
      send(res, 200, data);
    } catch (err) {
      console.error(`  fail ${req.url}: ${err.message}`);
      send(res, err.status && err.status >= 400 ? err.status : 502, { error: err.message });
    }
  });
});

function send(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`CookSmart Gemini proxy on http://127.0.0.1:${PORT}`);
    console.log(`  models: ${MODELS.join(", ")}`);
    console.log(`  photos: TheMealDB, then a seeded photograph, then a gradient`);
    console.log(
      process.env.GEMINI_API_KEY
        ? "  key   : loaded from GEMINI_API_KEY"
        : "  key   : MISSING - set $env:GEMINI_API_KEY before the app calls this",
    );
    console.log(`  phone : http://10.0.2.2:${PORT}`);
  });
}

module.exports = { server, buildRecipe, suggestDishes, generateImage, extractJson };
