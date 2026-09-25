import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, name, amount, currency, externalId, description, redirectUrl, metadata } = await req.json()

    // Validate currency - throw error if PHP
    if (currency && currency.toUpperCase() === 'PHP') {
      return new Response(JSON.stringify({ error: 'PHP currency is not supported for payments.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Retrieve Xendit secret key from Supabase Secrets (fallback to dummy for compilation/local run)
    const XENDIT_SECRET_KEY = Deno.env.get('XENDIT_SECRET_KEY') || 'xnd_development_YOUR_SANDBOX_SECRET_KEY';
    
    console.log(`Creating Xendit invoice for ${email} amount ${amount} ${currency}`);

    const response = await fetch("https://api.xendit.co/v2/invoices", {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(XENDIT_SECRET_KEY + ':'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        external_id: externalId,
        amount: amount,
        payer_email: email,
        description: description,
        customer: {
          given_names: name,
          email: email,
        },
        currency: currency ? currency.toUpperCase() : 'MYR',
        success_redirect_url: redirectUrl,
        failure_redirect_url: redirectUrl,
        metadata: metadata,
      }),
    })

    const data = await response.json()
    console.log("Xendit response:", data)

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: response.status,
    })
  } catch (error) {
    console.error("Error creating Xendit invoice:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
