import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    )

    const { kitchen_id } = await req.json()

    if (!kitchen_id) {
      return new Response(
        JSON.stringify({ error: 'Kitchen ID is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get today's date for order numbering
    const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
    
    // Get count of orders for today
    const { count } = await supabaseClient
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .eq('kitchen_id', kitchen_id)
      .gte('created_at', new Date().toISOString().split('T')[0] + 'T00:00:00.000Z')
      .lt('created_at', new Date(Date.now() + 24*60*60*1000).toISOString().split('T')[0] + 'T00:00:00.000Z')

    const orderNumber = `ORD-${today}-${String((count || 0) + 1).padStart(3, '0')}`

    return new Response(
      JSON.stringify({ order_number: orderNumber }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})