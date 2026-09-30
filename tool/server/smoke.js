// Smoke-tests a CookSmart AI server the way the Flutter app will call it.
//
//   node tool/server/smoke.js [--port 8787] [--label "real Groq"]
//
// Defaults to the offline mock on 8788. Point it at 8787 to exercise groq_proxy.js.
const http = require("http");

const port = Number(argValue("--port") || 8788);
const label = argValue("--label") || (port === 8787 ? "real Groq" : "offline mock");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : undefined;
}

function post(path, body) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);
    const req = http.request(
      {
        method: "POST",
        host: "127.0.0.1",
        port,
        path,
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload) },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => resolve({ status: res.statusCode, body: raw ? JSON.parse(raw) : null }));
      }
    );
    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

function get(path) {
  return new Promise((resolve, reject) => {
    http
      .get({ host: "127.0.0.1", port, path }, (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => resolve({ status: res.statusCode, type: res.headers["content-type"], bytes: raw.length, head: raw.slice(0, 4).toString("hex") }));
      })
      .on("error", reject);
  });
}

(async () => {
  console.log(`== ${label} on 127.0.0.1:${port} ==`);

  const recipe = await post("/groq/recipe", { ingredients: ["chicken", "lemon", "garlic"], servings: 2 });
  console.log("recipe status", recipe.status);
  console.log("  name       ", recipe.body.name);
  console.log("  time/diff  ", recipe.body.timeMinutes, recipe.body.difficulty);
  console.log("  ingredients", recipe.body.ingredients.length, "steps", recipe.body.steps.length);
  console.log("  owned      ", recipe.body.owned.join(", "));
  console.log("  missing    ", recipe.body.missing.join(", "));
  console.log("  imagePrompt", recipe.body.imagePrompt);

  const sug = await post("/groq/suggest", { count: 5 });
  console.log("suggest status", sug.status, "->", sug.body.names.join(" | "));

  const sug2 = await post("/groq/suggest", { query: "ramen", count: 5 });
  console.log("suggest(q)    ->", sug2.body.names.join(" | "));

  const img = await post("/groq/image", { prompt: recipe.body.imagePrompt, dish: recipe.body.name });
  console.log("image status", img.status, "->", img.body.url, "provider:", img.body.provider);
  const fetched = img.body.url.startsWith("/") ? await get(img.body.url) : null;
  if (fetched) console.log("image fetch  ", fetched.status, fetched.type, fetched.bytes, "bytes");

  const dish = await post("/groq/recipe", { dish: "Miso Butter Ramen" });
  console.log("dish-only    ", dish.status, "->", dish.body.name, "| owned:", JSON.stringify(dish.body.owned));
  const dishImg = await post("/groq/image", { prompt: dish.body.imagePrompt, dish: dish.body.name });
  console.log("dish image   ->", dishImg.body.url, "provider:", dishImg.body.provider);

  const bad = await post("/groq/recipe", { ingredients: [] });
  console.log("empty ingredients ->", bad.status, JSON.stringify(bad.body));
})();
