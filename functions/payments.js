/**
 * Firebase Cloud Functions - Payments Module (Stripe)
 */

const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

// Define Stripe secret once at top-level
const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");

exports.createPaymentIntent = onRequest(
    {
      cors: true,
      region: "us-central1",
      secrets: [STRIPE_SECRET_KEY],
    },
    async (req, res) => {
      // Init Stripe with secret value at runtime
      const stripeSecretKey = STRIPE_SECRET_KEY.value();
      const stripe = require("stripe")(stripeSecretKey);

      // CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");

      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({error: "Method Not Allowed"});
        return;
      }

      try {
        const {amount, currency} = req.body;

        // Validate input
        if (!amount || !currency) {
          res.status(400).json({
            error: "Missing required fields",
            message: "amount and currency are required",
          });
          return;
        }

        // Validate amount (phải là số dương)
        const amountNum = parseFloat(amount);
        if (isNaN(amountNum) || amountNum <= 0) {
          res.status(400).json({
            error: "Invalid amount",
            message: "amount must be a positive number",
          });
          return;
        }

        // Validate currency
        const validCurrencies = ["vnd", "usd", "eur", "gbp"];
        const currencyLower = String(currency).toLowerCase();
        if (!validCurrencies.includes(currencyLower)) {
          res.status(400).json({
            error: "Invalid currency",
            message: `currency must be one of: ${validCurrencies.join(", ")}`,
          });
          return;
        }

        // Convert to smallest currency unit per Stripe rules
        // - vnd: 0-decimal (no multiply)
        // - usd/eur/gbp: 2-decimal (multiply by 100)
        const smallestUnitAmount =
          currencyLower === "vnd"
            ? Math.round(amountNum)
            : Math.round(amountNum * 100);

        console.log(
            `Creating payment intent: ${amountNum} ${currencyLower} => smallest unit ${smallestUnitAmount}`,
        );

        const paymentIntent = await stripe.paymentIntents.create({
          amount: smallestUnitAmount,
          currency: currencyLower,
          automatic_payment_methods: {enabled: true},
          metadata: {created_at: new Date().toISOString()},
        });

        res.status(200).json({
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
        });
      } catch (error) {
        console.error("Error creating payment intent:", error);

        if (error.type === "StripeCardError") {
          res.status(400).json({
            error: "Stripe Card Error",
            message: error.message,
          });
        } else if (error.type === "StripeInvalidRequestError") {
          res.status(400).json({
            error: "Stripe Invalid Request",
            message: error.message,
          });
        } else {
          res.status(500).json({
            error: "Internal Server Error",
            message: error.message || "Failed to create payment intent",
          });
        }
      }
    },
);





















