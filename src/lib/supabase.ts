import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const signIn = async (email: string, password: string) => {
  // Check if this is a demo credential attempt
  const demoCredentials = [
    { email: 'admin@teetours.com', password: 'admin123' },
    { email: 'owner@restaurant.com', password: 'owner123' }
  ];
  
  const isDemoCredential = demoCredentials.some(
    cred => cred.email === email && cred.password === password
  );
  
  // First try to sign in
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });
  
  // If login fails with invalid credentials and it's a demo credential, try to create the user
  if (error && error.message.includes('Invalid login credentials') && isDemoCredential) {
    console.log('Demo user not found, attempting to create:', email);
    
    // Try to create the demo user
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
    });
    
    if (signUpError) {
      console.error('Failed to create demo user:', signUpError);
      return { data: null, error };
    }
    
    // If user was created successfully, try to sign in again
    if (signUpData.user) {
      console.log('Demo user created successfully, signing in:', email);
      return await supabase.auth.signInWithPassword({
        email,
        password,
      });
    }
  }
  
  return { data, error };
};

export const signUp = async (email: string, password: string) => {
  return await supabase.auth.signUp({
    email,
    password,
  });
};

export const signOut = async () => {
  return await supabase.auth.signOut();
};

export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
};