const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

initializeApp();

const db = getFirestore();
const region = "asia-southeast2";
const xenditSecretKey = defineSecret("XENDIT_SECRET_KEY");
const xenditCallbackToken = defineSecret("XENDIT_CALLBACK_TOKEN");

exports.createXenditInvoice = onCall(
  { region, secrets: [xenditSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to place an order.");
    }

    const orderId = request.data?.orderId;
    if (typeof orderId !== "string" || !orderId) {
      throw new HttpsError("invalid-argument", "A valid order ID is required.");
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();
    if (!orderDoc.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderDoc.data();
    if (order.userId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You cannot pay for this order.");
    }
    if (order.paymentMethod !== "online") {
      throw new HttpsError("failed-precondition", "This order is not an online order.");
    }

    const customerEmail =
      typeof request.data.customerEmail === "string"
        ? request.data.customerEmail
        : undefined;

    const response = await fetch("https://api.xendit.co/v2/invoices", {
      method: "POST",
      headers: {
        Authorization: `Basic ${Buffer.from(`${xenditSecretKey.value()}:`).toString("base64")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: orderId,
        amount: Number(order.total),
        currency: "PHP",
        description: `Becky's Kitchen order #${orderId.substring(0, 6).toUpperCase()}`,
        payer_email: customerEmail,
        invoice_duration: 86400,
      }),
    });

    const invoice = await response.json();
    if (!response.ok) {
      console.error("Xendit invoice creation failed", invoice);
      throw new HttpsError(
        "internal",
        invoice.message || "Unable to create the Xendit payment.",
      );
    }

    await orderRef.update({
      xenditInvoiceId: invoice.id,
      paymentStatus: "pending",
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { invoiceUrl: invoice.invoice_url };
  },
);

exports.xenditWebhook = onRequest(
  { region, secrets: [xenditCallbackToken] },
  async (request, response) => {
    if (
      request.header("x-callback-token") !== xenditCallbackToken.value()
    ) {
      response.status(401).send("Invalid callback token");
      return;
    }

    const invoice = request.body;
    const externalId = invoice.external_id;
    const xenditStatus = String(invoice.status || "").toUpperCase();
    if (typeof externalId !== "string" || !externalId) {
      response.status(400).send("Missing external_id");
      return;
    }

    let paymentStatus;
    if (xenditStatus === "PAID" || xenditStatus === "SETTLED") {
      paymentStatus = "paid";
    } else if (xenditStatus === "EXPIRED") {
      paymentStatus = "expired";
    } else {
      response.status(200).send("Ignored");
      return;
    }

    const update = {
      paymentStatus,
      xenditInvoiceId: invoice.id || "",
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (paymentStatus === "paid") {
      update.paymentPaidAt = FieldValue.serverTimestamp();
    }

    await db.collection("orders").doc(externalId).update(update);
    response.status(200).send("OK");
  },
);
