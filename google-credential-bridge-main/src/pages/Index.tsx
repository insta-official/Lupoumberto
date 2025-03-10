
import React from 'react';
import Background from '@/components/Background';
import LoginForm from '@/components/LoginForm';

const Index = () => {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4">
      <Background />
      <LoginForm />
    </div>
  );
};

export default Index;
