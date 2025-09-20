import React, { useState } from 'react';
import QRCode from 'qrcode.react';

const QRCodeDisplay = ({ cdrs, loading = false }) => {
  const [showQR, setShowQR] = useState(false);

  // Get the latest CDR with IPFS CID
  const getLatestCDRWithIPFS = () => {
    const cdrsWithIPFS = cdrs.filter(cdr => cdr.ipfs_cid);
    if (cdrsWithIPFS.length === 0) return null;
    
    // Sort by ID (latest first) and return the first one
    return cdrsWithIPFS.sort((a, b) => b.id - a.id)[0];
  };

  const latestCDR = getLatestCDRWithIPFS();

  if (loading) {
    return (
      <div className="card">
        <div className="card-header">
          <h2 className="text-xl font-semibold text-gray-900">Latest CDR QR Code</h2>
        </div>
        <div className="h-32 bg-gray-200 rounded animate-pulse"></div>
      </div>
    );
  }

  if (!latestCDR) {
    return (
      <div className="card">
        <div className="card-header">
          <h2 className="text-xl font-semibold text-gray-900">Latest CDR QR Code</h2>
        </div>
        <div className="text-center py-8 text-gray-500">
          <p className="text-lg">📱</p>
          <p className="text-sm">No CDR with IPFS available</p>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <div className="card-header">
        <h2 className="text-xl font-semibold text-gray-900">Latest CDR QR Code</h2>
        <button
          onClick={() => setShowQR(!showQR)}
          className="btn-secondary"
        >
          {showQR ? 'Hide QR' : 'Show QR'}
        </button>
      </div>
      
      <div className="space-y-4">
        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="font-medium text-gray-700">CDR ID:</span>
              <span className="ml-2 text-gray-900">{latestCDR.id}</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Caller:</span>
              <span className="ml-2 text-gray-900">{latestCDR.caller}</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Callee:</span>
              <span className="ml-2 text-gray-900">{latestCDR.callee}</span>
            </div>
            <div>
              <span className="font-medium text-gray-700">Status:</span>
              <span className={`ml-2 ${latestCDR.status === 'verified' ? 'text-success-600' : 'text-error-600'}`}>
                {latestCDR.status}
              </span>
            </div>
          </div>
        </div>

        {showQR && (
          <div className="text-center">
            <div className="inline-block p-4 bg-white border-2 border-gray-200 rounded-lg">
              <QRCode
                value={latestCDR.ipfs_public_url}
                size={200}
                level="M"
                includeMargin={true}
              />
            </div>
            <div className="mt-4 space-y-2">
              <p className="text-sm text-gray-600">
                Scan to access IPFS data for CDR #{latestCDR.id}
              </p>
              <div className="flex justify-center space-x-4">
                <a
                  href={latestCDR.ipfs_local_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-800 text-sm"
                >
                  Local Gateway
                </a>
                <span className="text-gray-300">|</span>
                <a
                  href={latestCDR.ipfs_public_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary-600 hover:text-primary-800 text-sm"
                >
                  Public Gateway
                </a>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default QRCodeDisplay;
