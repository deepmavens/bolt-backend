/*
  # Complete Tee Tours POS Database Schema

  1. New Tables
    - `profiles` - User profiles with role-based access
    - `kitchens` - Restaurant/kitchen information
    - `kitchen_subscriptions` - Subscription plans and billing
    - `menu_categories` - Menu organization
    - `menu_items` - Individual menu items
    - `combo_meals` - Combo meal packages
    - `combo_items` - Items within combo meals
    - `orders` - Customer orders
    - `order_items` - Items within orders
    - `qr_codes` - QR code management
    - `customers` - Customer information
    - `notifications` - System notifications
    - `audit_logs` - System audit trail
    - `revenue_tracking` - Revenue and commission tracking

  2. Security
    - Enable RLS on all tables
    - Add comprehensive policies for role-based access
    - Super Admin: Full access to all data
    - Kitchen Owner: Access only to their kitchen data

  3. Indexes and Constraints
    - Foreign key relationships
    - Performance indexes
    - Data validation constraints
*/

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('super_admin', 'kitchen_owner');
CREATE TYPE kitchen_status AS ENUM ('active', 'inactive', 'blocked', 'pending');
CREATE TYPE subscription_plan AS ENUM ('basic', 'premium', 'enterprise');
CREATE TYPE order_status AS ENUM ('pending', 'preparing', 'ready', 'delivered', 'cancelled');
CREATE TYPE order_type AS ENUM ('dine_in', 'takeaway', 'golf_course', 'delivery');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE notification_type AS ENUM ('order', 'system', 'payment', 'subscription');

-- Profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role user_role NOT NULL DEFAULT 'kitchen_owner',
  phone text,
  avatar_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Kitchens table
CREATE TABLE IF NOT EXISTS kitchens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  address text NOT NULL,
  phone text,
  email text,
  custom_domain text UNIQUE,
  logo_url text,
  status kitchen_status DEFAULT 'pending',
  subscription_plan subscription_plan DEFAULT 'basic',
  subscription_expires_at timestamptz,
  settings jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Kitchen subscriptions tracking
CREATE TABLE IF NOT EXISTS kitchen_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  plan subscription_plan NOT NULL,
  price_per_month decimal(10,2) NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  payment_status payment_status DEFAULT 'pending',
  stripe_subscription_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Menu categories
CREATE TABLE IF NOT EXISTS menu_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Menu items
CREATE TABLE IF NOT EXISTS menu_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  category_id uuid REFERENCES menu_categories(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  image_url text,
  is_available boolean DEFAULT true,
  is_special boolean DEFAULT false,
  allergens text[],
  nutritional_info jsonb,
  preparation_time integer, -- in minutes
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Combo meals
CREATE TABLE IF NOT EXISTS combo_meals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  price decimal(10,2) NOT NULL,
  image_url text,
  is_available boolean DEFAULT true,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Combo meal items (junction table)
CREATE TABLE IF NOT EXISTS combo_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  combo_id uuid REFERENCES combo_meals(id) ON DELETE CASCADE,
  menu_item_id uuid REFERENCES menu_items(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1,
  created_at timestamptz DEFAULT now()
);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text,
  phone text,
  member_number text,
  address text,
  customer_type text DEFAULT 'guest', -- guest, member, vip
  total_orders integer DEFAULT 0,
  total_spent decimal(10,2) DEFAULT 0,
  last_order_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  order_number text NOT NULL,
  customer_name text NOT NULL,
  customer_phone text,
  customer_email text,
  order_type order_type NOT NULL,
  table_number text,
  location_details text, -- for golf course orders
  status order_status DEFAULT 'pending',
  subtotal decimal(10,2) NOT NULL,
  tax_amount decimal(10,2) DEFAULT 0,
  tip_amount decimal(10,2) DEFAULT 0,
  total_amount decimal(10,2) NOT NULL,
  payment_status payment_status DEFAULT 'pending',
  payment_method text,
  special_instructions text,
  estimated_ready_time timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Order items
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id uuid REFERENCES menu_items(id) ON DELETE SET NULL,
  combo_meal_id uuid REFERENCES combo_meals(id) ON DELETE SET NULL,
  item_name text NOT NULL,
  item_price decimal(10,2) NOT NULL,
  quantity integer NOT NULL,
  special_instructions text,
  created_at timestamptz DEFAULT now()
);

-- QR Codes
CREATE TABLE IF NOT EXISTS qr_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  name text NOT NULL,
  qr_type text NOT NULL, -- table, golf_course, bar, takeaway
  location text NOT NULL,
  url text NOT NULL,
  scan_count integer DEFAULT 0,
  is_active boolean DEFAULT true,
  last_scanned_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE SET NULL,
  action text NOT NULL,
  table_name text NOT NULL,
  record_id uuid,
  old_values jsonb,
  new_values jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Revenue tracking
CREATE TABLE IF NOT EXISTS revenue_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kitchen_id uuid REFERENCES kitchens(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES kitchen_subscriptions(id) ON DELETE SET NULL,
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
  revenue_type text NOT NULL, -- subscription, commission, order
  amount decimal(10,2) NOT NULL,
  commission_rate decimal(5,2), -- for commission-based revenue
  period_start timestamptz,
  period_end timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_kitchens_owner_id ON kitchens(owner_id);
CREATE INDEX IF NOT EXISTS idx_kitchens_status ON kitchens(status);
CREATE INDEX IF NOT EXISTS idx_kitchens_custom_domain ON kitchens(custom_domain);
CREATE INDEX IF NOT EXISTS idx_menu_items_kitchen_id ON menu_items(kitchen_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category_id ON menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_is_available ON menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_orders_kitchen_id ON orders(kitchen_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_customers_kitchen_id ON customers(kitchen_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_kitchen_id ON qr_codes(kitchen_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_revenue_tracking_kitchen_id ON revenue_tracking(kitchen_id);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchens ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Super admins can read all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

CREATE POLICY "Super admins can manage all profiles"
  ON profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for kitchens
CREATE POLICY "Kitchen owners can read own kitchen"
  ON kitchens FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid());

CREATE POLICY "Kitchen owners can update own kitchen"
  ON kitchens FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid());

CREATE POLICY "Super admins can manage all kitchens"
  ON kitchens FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for menu_categories
CREATE POLICY "Kitchen owners can manage own menu categories"
  ON menu_categories FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all menu categories"
  ON menu_categories FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for menu_items
CREATE POLICY "Kitchen owners can manage own menu items"
  ON menu_items FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all menu items"
  ON menu_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for combo_meals
CREATE POLICY "Kitchen owners can manage own combo meals"
  ON combo_meals FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all combo meals"
  ON combo_meals FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for combo_items
CREATE POLICY "Kitchen owners can manage own combo items"
  ON combo_items FOR ALL
  TO authenticated
  USING (
    combo_id IN (
      SELECT id FROM combo_meals 
      WHERE kitchen_id IN (
        SELECT id FROM kitchens WHERE owner_id = auth.uid()
      )
    )
  );

CREATE POLICY "Super admins can manage all combo items"
  ON combo_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for customers
CREATE POLICY "Kitchen owners can manage own customers"
  ON customers FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all customers"
  ON customers FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for orders
CREATE POLICY "Kitchen owners can manage own orders"
  ON orders FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all orders"
  ON orders FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for order_items
CREATE POLICY "Kitchen owners can manage own order items"
  ON order_items FOR ALL
  TO authenticated
  USING (
    order_id IN (
      SELECT id FROM orders 
      WHERE kitchen_id IN (
        SELECT id FROM kitchens WHERE owner_id = auth.uid()
      )
    )
  );

CREATE POLICY "Super admins can manage all order items"
  ON order_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for qr_codes
CREATE POLICY "Kitchen owners can manage own QR codes"
  ON qr_codes FOR ALL
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all QR codes"
  ON qr_codes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Super admins can manage all notifications"
  ON notifications FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for kitchen_subscriptions
CREATE POLICY "Kitchen owners can read own subscriptions"
  ON kitchen_subscriptions FOR SELECT
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all subscriptions"
  ON kitchen_subscriptions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for audit_logs
CREATE POLICY "Super admins can read all audit logs"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- RLS Policies for revenue_tracking
CREATE POLICY "Kitchen owners can read own revenue"
  ON revenue_tracking FOR SELECT
  TO authenticated
  USING (
    kitchen_id IN (
      SELECT id FROM kitchens WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage all revenue tracking"
  ON revenue_tracking FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Create functions for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    COALESCE(new.raw_user_meta_data->>'role', 'kitchen_owner')::user_role
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Create function for updating timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON kitchens FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON kitchen_subscriptions FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON menu_categories FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON menu_items FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON combo_meals FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON qr_codes FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();

-- Create function for audit logging
CREATE OR REPLACE FUNCTION public.audit_trigger()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, new_values)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values, new_values)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_values)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, OLD.id, to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create audit triggers for important tables
CREATE TRIGGER audit_kitchens AFTER INSERT OR UPDATE OR DELETE ON kitchens FOR EACH ROW EXECUTE PROCEDURE audit_trigger();
CREATE TRIGGER audit_orders AFTER INSERT OR UPDATE OR DELETE ON orders FOR EACH ROW EXECUTE PROCEDURE audit_trigger();
CREATE TRIGGER audit_menu_items AFTER INSERT OR UPDATE OR DELETE ON menu_items FOR EACH ROW EXECUTE PROCEDURE audit_trigger();