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

    // Billplz sends data as x-www-form-urlencoded
    const formData = await req.formData()
    const billId = formData.get('id')
    const paid = formData.get('paid')
    const xSignature = formData.get('x_signature')

    console.log(`Received callback for Bill ID: ${billId}, Paid: ${paid}`)

    if (!billId) {
      throw new Error("Missing Bill ID")
    }

    // Optional: Verify X-Signature if key is provided
    // const signatureKey = Deno.env.get('BILLPLZ_X_SIGNATURE_KEY')
    // if (signatureKey) { ... verify ... }

    const isPaid = paid === 'true' || paid === true

    // Update the subscription_payments table
    // We match by transaction_id (which is the BillId from Billplz)
    const { data, error } = await supabase
      .from('subscription_payments')
      .update({ 
        payment_status: isPaid ? 'completed' : 'failed',
        updated_at: new Date().toISOString()
      })
      .eq('transaction_id', billId)
      .select()

    if (error) throw error

    console.log("Database update result:", data)

    return new Response(JSON.stringify({ success: true, message: "Callback processed" }), {
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
