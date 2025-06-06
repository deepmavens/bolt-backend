
import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Crown, Building2, Eye, EyeOff } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const Login = () => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    role: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const navigate = useNavigate();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Login attempt:', formData);
    
    // Mock login logic
    if (formData.role === 'super_admin') {
      localStorage.setItem('userRole', 'super_admin');
      localStorage.setItem('userEmail', formData.email);
      navigate('/');
    } else if (formData.role === 'kitchen_owner') {
      localStorage.setItem('userRole', 'kitchen_owner');
      localStorage.setItem('userEmail', formData.email);
      navigate('/');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">Tee Tours POS</h1>
          <p className="text-gray-600">Sign in to your admin panel</p>
        </div>

        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle>Welcome Back</CardTitle>
            <CardDescription>
              Choose your role and sign in to continue
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleLogin} className="space-y-6">
              {/* Role Selection */}
              <div>
                <Label htmlFor="role">Login As *</Label>
                <Select value={formData.role} onValueChange={(value) => setFormData({...formData, role: value})}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select your role" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="super_admin">
                      <div className="flex items-center">
                        <Crown className="h-4 w-4 mr-2 text-yellow-600" />
                        Super Admin
                      </div>
                    </SelectItem>
                    <SelectItem value="kitchen_owner">
                      <div className="flex items-center">
                        <Building2 className="h-4 w-4 mr-2 text-blue-600" />
                        Kitchen Owner
                      </div>
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Email */}
              <div>
                <Label htmlFor="email">Email Address *</Label>
                <Input
                  id="email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({...formData, email: e.target.value})}
                  placeholder="Enter your email"
                  required
                />
              </div>

              {/* Password */}
              <div>
                <Label htmlFor="password">Password *</Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    placeholder="Enter your password"
                    required
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </Button>
                </div>
              </div>

              {/* Login Button */}
              <Button 
                type="submit" 
                className="w-full"
                disabled={!formData.email || !formData.password || !formData.role}
              >
                Sign In
              </Button>

              {/* Signup Link for Kitchen Owners */}
              <div className="text-center text-sm">
                <span className="text-gray-600">Kitchen owner without an account? </span>
                <Button 
                  variant="link" 
                  className="p-0 h-auto font-medium"
                  onClick={() => navigate('/registration')}
                >
                  Register here
                </Button>
              </div>

              {/* Demo Credentials */}
              <div className="bg-gray-50 p-4 rounded-lg">
                <h4 className="font-medium text-sm mb-2">Demo Credentials:</h4>
                <div className="text-xs space-y-1">
                  <div><strong>Super Admin:</strong> admin@teetours.com / admin123</div>
                  <div><strong>Kitchen Owner:</strong> owner@restaurant.com / owner123</div>
                </div>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Login;
