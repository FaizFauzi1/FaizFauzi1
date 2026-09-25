import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Verify token if configured
    const callbackToken = Deno.env.get('XENDIT_CALLBACK_TOKEN')
    const incomingToken = req.headers.get('x-callback-token')

    if (callbackToken && incomingToken !== callbackToken) {
      console.warn("Unauthorized: x-callback-token does not match configured secret")
      return new Response(JSON.stringify({ error: "Invalid callback token" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    const payload = await req.json()
    const invoiceId = payload.id
    const externalId = payload.external_id
    const status = payload.status

    console.log(`Received Xendit webhook. Invoice ID: ${invoiceId}, External ID: ${externalId}, Status: ${status}`)

    if (!invoiceId) {
      throw new Error("Missing Invoice ID")
    }

    const isPaid = status === 'PAID' || status === 'SETTLED'
    const isFailed = status === 'EXPIRED'

    // Update the subscription_payments table. 
    // We check if there's a record matching either transaction_id = invoiceId OR transaction_id = externalId
    let query = supabase.from('subscription_payments').update({
      payment_status: isPaid ? 'completed' : (isFailed ? 'failed' : 'pending'),
      updated_at: new Date().toISOString()
    })

    // Try finding by externalId first
    let result = await query.eq('transaction_id', externalId).select()
    
    // If not found, try finding by invoiceId
    if (!result.data || result.data.length === 0) {
      console.log(`No records updated with transaction_id = ${externalId}. Trying invoiceId = ${invoiceId}...`)
      result = await supabase
        .from('subscription_payments')
        .update({
          payment_status: isPaid ? 'completed' : (isFailed ? 'failed' : 'pending'),
          updated_at: new Date().toISOString()
        })
        .eq('transaction_id', invoiceId)
        .select()
    }

    console.log("Database update result:", result.data)

    if (result.error) {
      throw result.error
    }

    return new Response(JSON.stringify({ success: true, message: "Callback processed successfully", data: result.data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error("Webhook Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
