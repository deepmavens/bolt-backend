/*
  # Create Super Admin User

  1. New Data
    - Insert a super admin user into the profiles table
    - Email: admin@teetours.com
    - Role: super_admin
    - Full name: Super Admin
    - Active status: true

  2. Notes
    - This creates a profile entry that will be linked when the user signs up
    - The user will need to sign up with the email admin@teetours.com
    - Password will be set during the signup process
*/

-- Insert super admin profile
INSERT INTO profiles (
  id,
  email,
  full_name,
  role,
  is_active,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'admin@teetours.com',
  'Super Admin',
  'super_admin',
  true,
  now(),
  now()
) ON CONFLICT (email) DO UPDATE SET
  role = 'super_admin',
  full_name = 'Super Admin',
  is_active = true,
  updated_at = now();