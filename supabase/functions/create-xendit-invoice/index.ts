import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const token = request.headers.get("authorization")?.replace("Bearer ", "");
    if (!token) throw Object.assign(new Error("Sign in first."), { status: 401 });

    const body = await request.json();
    const orderId = body.orderId;
    if (typeof orderId !== "string" || !orderId) {
      throw Object.assign(new Error("Order ID is required."), { status: 400 });
    }

    const firebaseProjectId = "becky-s-kitchen-e-commerce";
    const firestoreUrl =
      `https://firestore.googleapis.com/v1/projects/${firebaseProjectId}/databases/(default)/documents/orders/${orderId}`;
    const firestoreResponse = await fetch(firestoreUrl, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!firestoreResponse.ok) {
      throw Object.assign(
        new Error("Order is not available or you cannot access it."),
        { status: 403 },
      );
    }

    const document = await firestoreResponse.json();
    const fields = document.fields ?? {};
    const userId = fields.userId?.stringValue;
    if (!userId) {
      throw Object.assign(new Error("Invalid order."), { status: 400 });
    }
    const total = Number(fields.total?.doubleValue ?? fields.total?.integerValue ?? 0);
    const paymentMethod = fields.paymentMethod?.stringValue;
    if (paymentMethod !== "online" || total <= 0) {
      throw Object.assign(
        new Error("This order cannot be paid online."),
        { status: 400 },
      );
    }

    const secretKey = Deno.env.get("XENDIT_SECRET_KEY");
    if (!secretKey) {
      throw Object.assign(new Error("Xendit secret is not configured."), {
        status: 500,
      });
    }

    const response = await fetch("https://api.xendit.co/v2/invoices", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${secretKey}:`)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: orderId,
        amount: Math.round(total * 100) / 100,
        currency: "PHP",
        description: `Becky's Kitchen order #${orderId.substring(0, 6).toUpperCase()}`,
        invoice_duration: 86400,
      }),
    });
    const invoice = await response.json();
    if (!response.ok) {
      throw Object.assign(
        new Error(invoice.message || "Unable to create Xendit invoice."),
        { status: 502 },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    await supabase.from("payments").upsert({
      order_id: orderId,
      provider: "xendit",
      invoice_id: invoice.id,
      amount: total,
      currency: "PHP",
      status: "pending",
    });

    return new Response(
      JSON.stringify({ invoiceUrl: invoice.invoice_url }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Error" }),
      {
        status: error?.status ?? 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
