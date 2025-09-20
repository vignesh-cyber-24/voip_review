import React, { useState, useEffect } from 'react';
import { cdrAPI } from '../api';

const HealthCheck = () => {
  const [status, setStatus] = useState('checking');
  const [message, setMessage] = useState('');

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await cdrAPI.healthCheck();
        setStatus('healthy');
        setMessage(response.message || 'Backend is running');
      } catch (error) {
        setStatus('unhealthy');
        if (error.code === 'ECONNREFUSED' || error.message.includes('Network Error')) {
          setMessage('Backend server is not running. Please start the FastAPI server on port 8000.');
        } else {
          setMessage(`Backend error: ${error.message}`);
        }
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 30000); // Check every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = () => {
    switch (status) {
      case 'healthy':
        return 'bg-success-50 text-success-700 border-success-200';
      case 'unhealthy':
        return 'bg-error-50 text-error-700 border-error-200';
      default:
        return 'bg-warning-50 text-warning-700 border-warning-200';
    }
  };

  const getStatusIcon = () => {
    switch (status) {
      case 'healthy':
        return '✅';
      case 'unhealthy':
        return '❌';
      default:
        return '🔄';
    }
  };

  return (
    <div className={`border px-4 py-2 rounded-lg text-sm ${getStatusColor()}`}>
      <div className="flex items-center space-x-2">
        <span>{getStatusIcon()}</span>
        <span className="font-medium">
          {status === 'checking' ? 'Checking backend...' : 'Backend Status'}
        </span>
        <span>•</span>
        <span>{message}</span>
      </div>
    </div>
  );
};

export default HealthCheck;
