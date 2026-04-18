// Supabase Edge Function: delete-account
//
// Deletes the currently authenticated user's account, including all their
// data (cascaded via ON DELETE CASCADE on the gems table foreign key).
//
// The client-side Admin API requires the service role key, which must never
// live on-device. This function holds the service role key as a secret and
// verifies the caller's identity via their JWT before acting.
//
// Deploy:
//   supabase functions deploy delete-account --no-verify-jwt
//
// Secrets required:
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
//   (SUPABASE_URL and SUPABASE_ANON_KEY are auto-provided by the runtime)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', {
      status: 405,
      headers: corsHeaders,
    })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Verify identity: use the caller's JWT to get their user object
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser()

  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey)

  // Delete all audio files in gems-audio/{userId}/ before removing the user.
  // The gems table rows cascade on auth.users deletion, but storage objects
  // are managed separately and will become orphaned without this step.
  try {
    const { data: files, error: listError } = await adminClient.storage
      .from('gems-audio')
      .list(user.id)

    if (!listError && files && files.length > 0) {
      const paths = files.map((f: { name: string }) => `${user.id}/${f.name}`)
      await adminClient.storage.from('gems-audio').remove(paths)
      console.log(`delete-account: removed ${paths.length} audio file(s) for`, user.id)
    }
  } catch (storageErr) {
    // Non-fatal — log and continue; user deletion is the priority
    console.warn('delete-account: storage cleanup failed (continuing)', storageErr)
  }

  // Delete the user via the admin API (service role only)
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id)

  if (deleteError) {
    console.error('delete-account: failed to delete user', user.id, deleteError)
    return new Response(
      JSON.stringify({ error: deleteError.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  }

  console.log('delete-account: deleted user', user.id)
  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
