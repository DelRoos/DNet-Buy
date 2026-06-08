/**
 * Script one-shot pour enregistrer l'URL du webhook DNet chez Sharepay.
 *
 * Usage:
 *   cd functions
 *   node scripts/setup-sharepay-webhook.js              # GET (lire la config actuelle)
 *   node scripts/setup-sharepay-webhook.js --update     # PATCH (mettre à jour vers l'URL DNet)
 *
 * Variables d'env (optionnelles):
 *   SHAREPAY_API_KEY     - sinon: lue en dur ci-dessous
 *   SHAREPAY_WEBHOOK_URL - sinon: URL de la Cloud Function par défaut
 */

const axios = require("axios");

const SHAREPAY_API_KEY =
  process.env.SHAREPAY_API_KEY ||
  "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";

const SHAREPAY_BASE_URL = "https://sharepay-api.te-sea.com";

// On garde le nom de Cloud Function "handleFreemopayWebhook" pour ne pas changer l'URL
// déjà connue de l'écosystème — c'est désormais un endpoint Sharepay côté code.
const DEFAULT_WEBHOOK_URL =
  process.env.SHAREPAY_WEBHOOK_URL ||
  "https://us-central1-dnet-29b02.cloudfunctions.net/handleFreemopayWebhook";

const headers = {
  "X-API-KEY": SHAREPAY_API_KEY,
  "Content-Type": "application/json",
  "Accept": "application/json",
};

async function getConfig() {
  const url = `${SHAREPAY_BASE_URL}/api/v1/webhook`;
  const resp = await axios.get(url, { headers, timeout: 10000 });
  return resp.data;
}

async function updateConfig(webhookUrl) {
  const url = `${SHAREPAY_BASE_URL}/api/v1/webhook`;
  const resp = await axios.patch(url, { webhookUrl }, { headers, timeout: 10000 });
  return resp.data;
}

(async () => {
  const args = process.argv.slice(2);
  const doUpdate = args.includes("--update");
  const customUrl = args.find((a) => a.startsWith("--url="));
  const targetUrl = customUrl ? customUrl.split("=")[1] : DEFAULT_WEBHOOK_URL;

  try {
    console.log("📡 Lecture de la config webhook Sharepay actuelle...");
    const current = await getConfig();
    console.log("Config actuelle:", JSON.stringify(current, null, 2));

    if (!doUpdate) {
      console.log("\nℹ️  Pour mettre à jour, relancez avec --update :");
      console.log(`   node scripts/setup-sharepay-webhook.js --update`);
      console.log(`   (URL cible: ${targetUrl})`);
      process.exit(0);
    }

    if (current.webhookUrl === targetUrl) {
      console.log(`\n✅ Webhook déjà configuré sur l'URL cible. Rien à faire.`);
      process.exit(0);
    }

    console.log(`\n🔄 Mise à jour de l'URL vers: ${targetUrl}`);
    const updated = await updateConfig(targetUrl);
    console.log("✅ Nouvelle config:", JSON.stringify(updated, null, 2));
  } catch (err) {
    if (err.response) {
      console.error(`❌ HTTP ${err.response.status}:`, JSON.stringify(err.response.data, null, 2));
    } else {
      console.error("❌ Erreur:", err.message);
    }
    process.exit(1);
  }
})();
