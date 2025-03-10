
import React, { useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import GoogleLogo from '@/components/GoogleLogo';

const Dashboard = () => {
  const navigate = useNavigate();
  
  useEffect(() => {
    toast.success("You're now signed in");
  }, []);
  
  const handleSignOut = () => {
    toast.info("Signing out...");
    setTimeout(() => {
      navigate('/');
    }, 1500);
  };
  
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b bg-white/80 backdrop-blur-subtle dark:bg-black/20 sticky top-0 z-10">
        <div className="container flex h-16 items-center justify-between">
          <div className="flex items-center gap-2">
            <GoogleLogo className="w-8 h-8" />
            <span className="font-medium">Google Dashboard</span>
          </div>
          <Button 
            variant="ghost" 
            className="text-sm"
            onClick={handleSignOut}
          >
            Sign out
          </Button>
        </div>
      </header>
      
      <main className="flex-1 container py-12">
        <div className="glass-card rounded-2xl p-8 shadow-lg animate-fade-in-up">
          <h1 className="text-3xl font-semibold mb-6">Welcome to your Dashboard</h1>
          <p className="text-muted-foreground mb-8">
            You've successfully signed in to your Google account.
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {['Gmail', 'Drive', 'Photos'].map((service) => (
              <div key={service} className="bg-white/50 dark:bg-black/10 backdrop-blur-subtle p-6 rounded-xl border hover:shadow-md transition-all duration-300">
                <h3 className="text-xl font-medium mb-2">{service}</h3>
                <p className="text-muted-foreground text-sm mb-4">Access your {service.toLowerCase()} and manage your content.</p>
                <Button variant="outline" className="w-full">Open {service}</Button>
              </div>
            ))}
          </div>
        </div>
      </main>
      
      <footer className="border-t py-6 bg-white/80 backdrop-blur-subtle dark:bg-black/20">
        <div className="container text-center text-sm text-muted-foreground">
          <p>© {new Date().getFullYear()} Google LLC. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Dashboard;
