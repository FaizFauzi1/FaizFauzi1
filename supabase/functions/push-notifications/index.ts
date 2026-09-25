import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

interface NotificationRecord {
  user_id: string
  title: string
  message: string
  type: string
  metadata?: any
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: NotificationRecord
  old_record: NotificationRecord | null
}

const getAccessToken = async (
  clientEmail: string,
  privateKey: string,
): Promise<string> => {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  }

  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  const encodedHeader = btoa(JSON.stringify(header))
  const encodedClaim = btoa(JSON.stringify(claim))
  const signatureInput = `${encodedHeader}.${encodedClaim}`

  const keyData = await crypto.subtle.importKey(
    'pkcs8',
    Uint8Array.from(atob(privateKey.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n/g, '')), c => c.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    keyData,
    new TextEncoder().encode(signatureInput),
  )

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')

  const jwt = `${signatureInput}.${encodedSignature}`

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const { access_token } = await response.json()
  return access_token
}

serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    const { record } = payload

    if (!record || !record.user_id) {
       return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Fetch user tokens
    const { data: tokens, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', record.user_id)

    if (tokenError) throw tokenError
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No tokens for user' }), { status: 200 })
    }

    // 2. Get FCM Access Token
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')!
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID')!
    
    const accessToken = await getAccessToken(clientEmail, privateKey)

    // 3. Send notifications
    const results = await Promise.all(
      tokens.map(async (t) => {
        try {
          const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({
                message: {
                  token: t.token,
                  notification: {
                    title: record.title,
                    body: record.message,
                  },
                  data: {
                    type: record.type,
                    ...record.metadata,
                  },
                },
              }),
            }
          )
          return res.ok
        } catch (e) {
          console.error('FCM Send Error:', e)
          return false
        }
      })
    )

    return new Response(JSON.stringify({ success: true, count: results.filter(Boolean).length }), { status: 200 })
  } catch (error) {
    console.error('Global Error:', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})
