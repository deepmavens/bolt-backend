import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database types
export interface Profile {
  id: string
  email: string
  full_name: string
  role: 'super_admin' | 'kitchen_owner'
  phone?: string
  avatar_url?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Kitchen {
  id: string
  owner_id: string
  name: string
  description?: string
  address: string
  phone?: string
  email?: string
  custom_domain?: string
  logo_url?: string
  status: 'active' | 'inactive' | 'blocked' | 'pending'
  subscription_plan: 'basic' | 'premium' | 'enterprise'
  subscription_expires_at?: string
  settings: Record<string, any>
  created_at: string
  updated_at: string
}

export interface MenuItem {
  id: string
  kitchen_id: string
  category_id?: string
  name: string
  description?: string
  price: number
  image_url?: string
  is_available: boolean
  is_special: boolean
  allergens?: string[]
  nutritional_info?: Record<string, any>
  preparation_time?: number
  display_order: number
  created_at: string
  updated_at: string
}

export interface Order {
  id: string
  kitchen_id: string
  customer_id?: string
  order_number: string
  customer_name: string
  customer_phone?: string
  customer_email?: string
  order_type: 'dine_in' | 'takeaway' | 'golf_course' | 'delivery'
  table_number?: string
  location_details?: string
  status: 'pending' | 'preparing' | 'ready' | 'delivered' | 'cancelled'
  subtotal: number
  tax_amount: number
  tip_amount: number
  total_amount: number
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded'
  payment_method?: string
  special_instructions?: string
  estimated_ready_time?: string
  completed_at?: string
  created_at: string
  updated_at: string
}

export interface Customer {
  id: string
  kitchen_id: string
  name: string
  email?: string
  phone?: string
  member_number?: string
  address?: string
  customer_type: string
  total_orders: number
  total_spent: number
  last_order_at?: string
  created_at: string
  updated_at: string
}

export interface QRCode {
  id: string
  kitchen_id: string
  name: string
  qr_type: string
  location: string
  url: string
  scan_count: number
  is_active: boolean
  last_scanned_at?: string
  created_at: string
  updated_at: string
}

// Auth helpers
export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  return user
}

export const getCurrentProfile = async () => {
  const user = await getCurrentUser()
  if (!user) return null

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return profile
}

export const signIn = async (email: string, password: string) => {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  })
  return { data, error }
}

export const signUp = async (email: string, password: string, userData: any) => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: userData
    }
  })
  return { data, error }
}

export const signOut = async () => {
  const { error } = await supabase.auth.signOut()
  return { error }
}