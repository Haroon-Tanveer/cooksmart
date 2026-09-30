/**
 * Shared route handling for the CookSmart Gemini proxy on Vercel.
 *
 * Vercel routes by filename, so there is one thin entry file per route under
 * api/gemini/. They all call into this module. An earlier version used a single
 * entry plus a rewrite, but the rewrite rewrote req.url and the handler could
 * no longer tell which route was being called, so every request 404'd.
 */
const {
  buildRecipe,
  suggestDishes,
  generateImage,
} = require("./groq_proxy.js");

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
      // Vercel caps request bodies well below this; nothing legitimate is close.
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

function json(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

/** Builds the Vercel handler for one named operation. */
function handle(operation) {
  return async (req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    if (req.method === "OPTIONS") {
      res.writeHead(204);
      return res.end();
    }

    if (operation === "health") {
      return json(res, 200, {
        ok: true,
        key: Boolean(process.env.GEMINI_API_KEY),
        runtime: process.env.VERCEL ? "vercel" : "node",
      });
    }

    let body;
    try {
      body = await readBody(req);
    } catch (err) {
      return json(res, err.status || 400, { error: err.message });
    }

    const started = Date.now();
    try {
      const data = await run(operation, body);
      console.log(`ok /gemini/${operation} (${Date.now() - started}ms)`);
      return json(res, 200, data);
    } catch (err) {
      console.error(`fail /gemini/${operation}: ${err.message}`);
      return json(res, err.status && err.status >= 400 ? err.status : 502, {
        error: err.message,
      });
    }
  };
}

async function run(operation, body) {
  if (operation === "recipe") {
    return buildRecipe(body.ingredients || [], body.servings, body.dish);
  }
  if (operation === "suggest") {
    return suggestDishes(body.query, body.count);
  }
  if (operation === "image") {
    if (!body.prompt && !body.dish) throw httpError("prompt is required", 400);
    return generateImage(body.prompt || body.dish, body.dish);
  }
  throw httpError("unknown endpoint", 404);
}

module.exports = { handle, run };
