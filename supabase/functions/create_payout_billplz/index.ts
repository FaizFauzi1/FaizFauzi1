import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      bankCode, 
      bankAccountNumber, 
      name, 
      amount, 
      description, 
      identityNumber, 
      isSandbox, 
      apiKey 
    } = await req.json()

    // Billplz API Key - Use passed one or environment variable
    const BILLPLZ_API_KEY = apiKey || Deno.env.get('BILLPLZ_API_KEY');
    
    if (!BILLPLZ_API_KEY) {
      throw new Error('Billplz API Key not provided')
    }

    const baseUrl = isSandbox 
      ? "https://www.billplz-sandbox.com/api/v3" 
      : "https://www.billplz.com/api/v3";

    console.log(`[Payout] Mode: ${isSandbox ? 'Sandbox' : 'Production'}`);
    console.log(`[Payout] Targeted URL: ${baseUrl}/mass_payment_instructions`);
    console.log(`[Payout] Amount: RM${amount/100}`);

    // Billplz Payout API uses mass_payment_instructions endpoint
    const response = await fetch(`${baseUrl}/mass_payment_instructions`, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(BILLPLZ_API_KEY + ':'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        bank_code: bankCode,
        bank_account_number: bankAccountNumber,
        name: name,
        amount: amount, 
        description: description,
        identity_number: identityNumber,
      }),
    })

    // 1. Check if the response is actually JSON
    const contentType = response.headers.get("content-type");
    if (contentType && contentType.indexOf("application/json") !== -1) {
      const data = await response.json();
      console.log("[Payout] Billplz JSON response:", data);

      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status,
      })
    } else {
      // 2. Handle non-JSON responses (HTML error pages from Billplz)
      const errorText = await response.text();
      console.error("[Payout] Billplz returned non-JSON response:", errorText);
      
      return new Response(JSON.stringify({ 
        error: `Billplz returned an error page (Status ${response.status}).`,
        details: errorText.substring(0, 500) // Send a snippet of the HTML error
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status || 400,
      })
    }

  } catch (error) {
    console.error("[Payout] Edge Function Crash:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
