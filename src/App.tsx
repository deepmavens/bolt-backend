
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Index from "./pages/Index";
import Orders from "./pages/Orders";
import Menu from "./pages/Menu";
import QRCodes from "./pages/QRCodes";
import Registration from "./pages/Registration";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import Analytics from "./pages/Analytics";
import Kitchens from "./pages/Kitchens";
import Revenue from "./pages/Revenue";
import Users from "./pages/Users";
import Customers from "./pages/Customers";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route path="/" element={<Index />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/menu" element={<Menu />} />
          <Route path="/qr-codes" element={<QRCodes />} />
          <Route path="/customers" element={<Customers />} />
          <Route path="/registration" element={<Registration />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/kitchens" element={<Kitchens />} />
          <Route path="/revenue" element={<Revenue />} />
          <Route path="/users" element={<Users />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
