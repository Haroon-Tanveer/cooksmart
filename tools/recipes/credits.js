/**
 * Fills in the author and licence for every Wikipedia photo.
 *
 *   node tools/recipes/credits.js
 *
 * The article's lead image says which file was used but not who owns it, and
 * attribution is not optional for most of these licences. Both lookups accept up
 * to 50 titles per request, so this makes a handful of calls rather than one per
 * photo; asking politely is the difference between a working run and an
 * immediate rate limit.
 */
const fs = require("fs");
const https = require("https");
const path = require("path");

const MANIFEST = path.join(__dirname, "wiki_manifest.json");
const CREDITS = path.join(__dirname, "PHOTO_CREDITS.md");
const API = "https://en.wikipedia.org/w/api.php";
const BATCH = 30;
const DELAY_MS = 2500;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function get(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(
      url,
      { headers: { "User-Agent": "CookSmart/1.0 (recipe app; local project)" } },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          res.resume();
          return resolve(get(res.headers.location));
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
        res.on("end", () => {
          try {
            resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error("timeout"));
    });
    req.on("error", reject);
  });
}

async function getJson(url, attempts = 4) {
  for (let i = 0; i < attempts; i++) {
    try {
      return await get(url);
    } catch (err) {
      if (i === attempts - 1) return null;
      await sleep(5000 * (i + 1));
    }
  }
  return null;
}

const strip = (s) => String(s || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();

/** The article title, taken back out of the stored page URL. */
function articleFrom(pageUrl) {
  if (!pageUrl) return null;
  const tail = pageUrl.split("/wiki/")[1];
  if (!tail) return null;
  try {
    return decodeURIComponent(tail.split("#")[0]);
  } catch (_) {
    return null;
  }
}

function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

/** One call returns the lead file name for up to BATCH articles. */
async function leadFiles(articles) {
  // No redirects=1: it renames the titles in the response, and the caller needs
  // to map them back to a recipe id. The titles used here already came from a
  // successful lookup, so they resolve as written.
  const url =
    `${API}?action=query&format=json&prop=pageimages&piprop=name&titles=` +
    encodeURIComponent(articles.join("|"));
  const data = await getJson(url);
  if (!data || !data.query) return {};

  // Undo the API's own normalisation so the keys match what we asked for.
  const alias = new Map();
  for (const list of [data.query.normalized, data.query.redirects]) {
    for (const item of list || []) alias.set(item.to, item.from);
  }

  const out = {};
  for (const page of Object.values(data.query.pages)) {
    if (!page.pageimage) continue;
    let title = page.title;
    for (let i = 0; i < 3 && alias.has(title); i++) title = alias.get(title);
    out[title] = `File:${page.pageimage}`;
  }
  return out;
}

/** One call returns author and licence for up to BATCH files. */
async function fileMeta(files) {
  const url =
    `${API}?action=query&format=json&prop=imageinfo&iiprop=extmetadata&titles=` +
    encodeURIComponent(files.join("|"));
  const data = await getJson(url);
  if (!data || !data.query) return {};
  const out = {};
  for (const page of Object.values(data.query.pages)) {
    const info = (page.imageinfo && page.imageinfo[0]) || null;
    if (!info) continue;
    const meta = info.extmetadata || {};
    // The API answers with "File:A B.jpg" even when asked for "File:A_B.jpg",
    // so the map is keyed on both spellings or every lookup misses.
    const entry = {
      artist: strip(meta.Artist && meta.Artist.value) || "unknown author",
      licence: strip(meta.LicenseShortName && meta.LicenseShortName.value) || "see file page",
      file: `https://commons.wikimedia.org/wiki/${encodeURIComponent(page.title)}`,
    };
    out[page.title] = entry;
    out[page.title.replace(/ /g, "_")] = entry;
  }
  return out;
}

(async () => {
  const manifest = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
  const ids = Object.keys(manifest);

  const articles = {};
  for (const id of ids) {
    if (manifest[id].artist && manifest[id].artist !== "see file page") continue;
    const a = articleFrom(manifest[id].title);
    if (a) articles[id] = a;
  }
  const pairs = Object.entries(articles);
  console.log(`${pairs.length} photos still need a credit, in ${Math.ceil(pairs.length / BATCH)} calls`);

  const idByArticle = {};
  for (const [id, article] of pairs) {
    // A redirect can rename the article, so key on the requested title too.
    idByArticle[article] = id;
  }

  let credited = 0;
  for (const group of chunk(pairs.map(([, a]) => a), BATCH)) {
    const fileByArticle = await leadFiles(group);
    await sleep(DELAY_MS);

    const wanted = [];
    for (const [article, file] of Object.entries(fileByArticle)) {
      const id = idByArticle[article];
      if (id) wanted.push([id, file]);
    }
    if (!wanted.length) continue;

    const meta = await fileMeta(wanted.map(([, f]) => f));
    await sleep(DELAY_MS);

    for (const [id, file] of wanted) {
      const m = meta[file];
      if (!m) continue;
      manifest[id].artist = m.artist;
      manifest[id].licence = m.licence;
      manifest[id].file = m.file;
      credited++;
    }
    fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 1));
  }

  const lines = [
    "# Recipe photo credits",
    "",
    "Photographs bundled with the library recipes. Author and licence were read from",
    "the Wikimedia Commons file description when the image was downloaded.",
    "",
    "Recipes with no entry here came from TheMealDB, whose free API does not",
    "require per-image attribution.",
    "",
    "| recipe id | author | licence | file |",
    "| --- | --- | --- | --- |",
  ];
  for (const [id, meta] of Object.entries(manifest).sort()) {
    const artist = meta.artist || "see file page";
    lines.push(`| \`${id}\` | ${artist} | ${meta.licence || "see file page"} | ${meta.file || meta.title} |`);
  }
  fs.writeFileSync(CREDITS, lines.join("\n"));

  console.log(`credited ${credited} of ${pairs.length}`);
})();
