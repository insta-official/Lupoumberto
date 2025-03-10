
import React from 'react';

const Background = () => {
  return (
    <div className="fixed inset-0 -z-10 overflow-hidden">
      <div className="absolute -top-[40%] -left-[20%] h-[800px] w-[800px] rounded-full bg-gradient-to-br from-google-blue/20 to-google-blue/5 blur-3xl animate-float"></div>
      <div className="absolute top-[10%] -right-[20%] h-[600px] w-[600px] rounded-full bg-gradient-to-br from-google-red/20 to-google-red/5 blur-3xl animate-float" style={{ animationDelay: '1s' }}></div>
      <div className="absolute -bottom-[20%] left-[10%] h-[700px] w-[700px] rounded-full bg-gradient-to-br from-google-green/20 to-google-green/5 blur-3xl animate-float" style={{ animationDelay: '2s' }}></div>
      <div className="absolute bottom-[10%] right-[10%] h-[500px] w-[500px] rounded-full bg-gradient-to-br from-google-yellow/20 to-google-yellow/5 blur-3xl animate-float" style={{ animationDelay: '3s' }}></div>
      
      <div className="absolute inset-0 bg-background/60 backdrop-blur-subtle"></div>
    </div>
  );
};

export default Background;
