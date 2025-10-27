// src/api.js
import axios from 'axios';
import CryptoJS from 'crypto-js';

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

// ===============================
// CDR Blockchain API Service
// ===============================
export const cdrAPI = {
  // Fetch all stored CDRs
  getAllCDRs: async () => {
    try {
      const response = await api.get('/cdrs');
      return response.data;
    } catch (error) {
      console.error('Error fetching CDRs:', error);
      throw error;
    }
  },

  // Fetch a single CDR by ID
  getCDR: async (id) => {
    try {
      const response = await api.get(`/cdr/${id}`);
      return response.data;
    } catch (error) {
      console.error(`Error fetching CDR ${id}:`, error);
      throw error;
    }
  },

  // Store a new CDR record on blockchain
  storeCDR: async (cdrData) => {
    try {
      // ✅ Build identical hash string to backend logic
      // Backend recomputes: f"{caller}{callee}{timestamp}{duration}{status}"
      const cdrString = `${cdrData.caller}${cdrData.callee}${cdrData.timestamp}${cdrData.duration}${cdrData.status}`;
      const hash = CryptoJS.SHA256(cdrString).toString(CryptoJS.enc.Hex);

      // Include the computed hash in payload
      const payload = { ...cdrData, hash };

      console.log(`[CDR HASH] Computed: ${hash}`);

      const response = await api.post('/store_cdr', payload);
      return response.data;
    } catch (error) {
      console.error('Error storing CDR:', error);
      throw error;
    }
  },

  // Get total blockchain record count
  getRecordCount: async () => {
    try {
      const response = await api.get('/record_count');
      return response.data;
    } catch (error) {
      console.error('Error fetching record count:', error);
      throw error;
    }
  },

  // Verify a stored CDR by blockchain index
  verifyCDR: async (idx, ipfsCid) => {
    try {
      // Backend route: /verify_cdr/{idx}
      const response = await api.get(`/verify_cdr/${idx}`, {
        params: { ipfs_cid: ipfsCid },
      });
      return response.data;
    } catch (error) {
      console.error(`Error verifying CDR ${idx}:`, error);
      throw error;
    }
  },

  // Health check for API status
  healthCheck: async () => {
    try {
      const response = await api.get('/');
      return response.data;
    } catch (error) {
      console.error('Health check failed:', error);
      throw error;
    }
  },
};

// ===============================
// Utility helper functions
// ===============================
export const utils = {
  // Convert Unix timestamp to local date/time
  formatTimestamp: (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = new Date(timestamp * 1000);
    return date.toLocaleString();
  },

  // Shorten long hashes for UI
  truncateHash: (hash, length = 8) => {
    if (!hash) return 'N/A';
    return `${hash.substring(0, length)}...${hash.substring(hash.length - length)}`;
  },

  // Assign CSS color by status
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

  // Human-friendly status names
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

  // Generate both local and public IPFS URLs
  getIPFSUrls: (cid) => {
    if (!cid) return { local: null, public: null };
    return {
      local: `http://127.0.0.1:8080/ipfs/${cid}`,
      public: `https://ipfs.io/ipfs/${cid}`,
    };
  },
};

export default api;
