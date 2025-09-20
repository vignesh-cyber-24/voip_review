import axios from 'axios';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging
api.interceptors.request.use(
  (config) => {
    console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    console.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    console.log(`API Response: ${response.status} ${response.config.url}`);
    return response;
  },
  (error) => {
    console.error('API Response Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

// API service functions
export const cdrAPI = {
  // Get all CDRs
  getAllCDRs: async () => {
    try {
      const response = await api.get('/cdrs');
      return response.data;
    } catch (error) {
      console.error('Error fetching CDRs:', error);
      throw error;
    }
  },

  // Get a specific CDR by ID
  getCDR: async (id) => {
    try {
      const response = await api.get(`/cdr/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching CDR ${id}:`, error);
      throw error;
    }
  },

  // Store a new CDR
  storeCDR: async (cdrData) => {
    try {
      const response = await api.post('/store_cdr', cdrData);
      return response.data;
    } catch (error) {
      console.error('Error storing CDR:', error);
      throw error;
    }
  },

  // Get total record count
  getRecordCount: async () => {
    try {
      const response = await api.get('/record_count');
      return response.data;
    } catch (error) {
      console.error('Error fetching record count:', error);
      throw error;
    }
  },

  // Verify a CDR
  verifyCDR: async (idx, ipfsCid) => {
    try {
      const response = await api.get(`/verify/${idx}`, {
        params: { ipfs_cid: ipfsCid }
      });
      return response.data;
    } catch (error) {
      console.error(`Error verifying CDR ${idx}:`, error);
      throw error;
    }
  },

  // Health check
  healthCheck: async () => {
    try {
      const response = await api.get('/');
      return response.data;
    } catch (error) {
      console.error('Health check failed:', error);
      throw error;
    }
  }
};

// Utility functions
export const utils = {
  // Format timestamp to readable date
  formatTimestamp: (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = new Date(timestamp * 1000); // Convert from Unix timestamp
    return date.toLocaleString();
  },

  // Truncate hash for display
  truncateHash: (hash, length = 8) => {
    if (!hash) return 'N/A';
    return `${hash.substring(0, length)}...${hash.substring(hash.length - length)}`;
  },

  // Get status color class
  getStatusColor: (status) => {
    switch (status) {
      case 'verified':
        return 'status-verified';
      case 'mismatch':
        return 'status-mismatch';
      case 'error':
      case 'no_ipfs':
        return 'status-error';
      default:
        return 'status-error';
    }
  },

  // Format status text
  formatStatus: (status) => {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'mismatch':
        return 'Mismatch';
      case 'error':
        return 'Error';
      case 'no_ipfs':
        return 'No IPFS';
      default:
        return 'Unknown';
    }
  },

  // Generate IPFS URLs
  getIPFSUrls: (cid) => {
    if (!cid) return { local: null, public: null };
    return {
      local: `http://127.0.0.1:8080/ipfs/${cid}`,
      public: `https://ipfs.io/ipfs/${cid}`
    };
  }
};

export default api;
