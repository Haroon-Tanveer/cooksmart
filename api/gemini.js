/**
 * CookSmart Gemini proxy as a Vercel serverless function.
 *
 * Vercel is serverless, so this exposes the same three routes the Flutter app
 * already calls, without a listening socket:
 *
 *   POST /api/gemini/recipe
 *   POST /api/gemini/suggest
 *   POST /api/gemini/image
 *
 * The Gemini key is read from the GEMINI_API_KEY environment variable, which
 * Vercel injects from the project's Environment settings. It is never compiled
 * into the function.
 *
 * One constraint to be aware of: a serverless function has a hard time limit,
 * 10s on the Hobby plan and 60s on Pro. The retry budget in gemini_proxy.js is
 * tuned to fit inside the Pro limit, so deploy on Pro if you want live recipes
 * to survive a busy moment at Gemini.
 */
const {
  buildRecipe,
  suggestDishes,
  generateImage,
} = require("../tool/server/gemini_proxy.js");

const ROUTES = {
  recipe: (body) => buildRecipe(body.ingredients || [], body.servings, body.dish),
  suggest: (body) => suggestDishes(body.query, body.count),
  image: (body) =>
    body.prompt || body.dish
      ? generateImage(body.prompt || body.dish, body.dish)
      : Promise.reject(httpError("prompt is required", 400)),
};

function httpError(message, status) {
  const err = new Error(message);
  err.status = status;
  return err;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (c) => {
      raw += c;
      // Vercel caps the body at 4.5 MB; nothing legitimate comes close.
      if (raw.length > 1e6) req.destroy();
    });
    req.on("end", () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        reject(httpError("body must be JSON", 400));
      }
    });
    req.on("error", reject);
  });
}

module.exports = async (req, res) => {
  // The app sends its own origins, and browsers preflight an unknown one.
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  const path = (req.url || "").split("?")[0];
  const name = path.split("/").filter(Boolean).pop();

  if (req.method === "GET" && name === "health") {
    return json(res, 200, {
      ok: true,
      key: Boolean(process.env.GEMINI_API_KEY),
    });
  }

  const handler = ROUTES[name];
  if (!handler) {
    return json(res, 404, { error: "unknown endpoint" });
  }

  let body;
  try {
    body = await readBody(req);
  } catch (err) {
    return json(res, err.status || 400, { error: err.message });
  }

  const started = Date.now();
  try {
    const data = await handler(body);
    console.log(`ok /gemini/${name} (${Date.now() - started}ms)`);
    return json(res, 200, data);
  } catch (err) {
    console.error(`fail /gemini/${name}: ${err.message}`);
    return json(res, err.status && err.status >= 400 ? err.status : 502, {
      error: err.message,
    });
  }
};

function json(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}
