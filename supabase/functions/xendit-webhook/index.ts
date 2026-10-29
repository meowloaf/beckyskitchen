const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-callback-token",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const callbackToken = request.headers.get("x-callback-token");
  if (callbackToken !== Deno.env.get("XENDIT_CALLBACK_TOKEN")) {
    return new Response("Invalid callback token", { status: 401 });
  }

  const invoice = await request.json();
  const orderId = invoice.external_id;
  const xenditStatus = String(invoice.status || "").toUpperCase();
  if (!orderId) {
    return new Response("Missing external_id", { status: 400 });
  }

  let status: string | null = null;
  if (xenditStatus === "PAID" || xenditStatus === "SETTLED") status = "paid";
  else if (xenditStatus === "EXPIRED") status = "expired";
  else return new Response("Ignored", { status: 200 });

  const { createClient } = await import("npm:@supabase/supabase-js@2");
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supabase.from("payments").upsert({
    order_id: orderId,
    provider: "xendit",
    invoice_id: invoice.id ?? null,
    amount: Number(invoice.amount ?? 0),
    currency: invoice.currency ?? "PHP",
    status,
    paid_at: status === "paid" ? new Date().toISOString() : null,
  });
  if (error) {
    return new Response(error.message, { status: 500 });
  }
  return new Response("OK", { status: 200 });
});
