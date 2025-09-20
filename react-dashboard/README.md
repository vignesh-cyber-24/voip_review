# 🛰 CDR Blockchain + IPFS Dashboard (React.js)

A modern React.js frontend for the VoIP CDR Blockchain + IPFS system, replacing the original Streamlit dashboard with a responsive, feature-rich web application.

## Features

- **Real-time Dashboard**: Auto-refreshes every 5 seconds to display latest CDR data
- **Statistics Cards**: Shows total CDRs, verified records, IPFS-backed records, and errors
- **Interactive Table**: Sortable CDR table with verification status and IPFS links
- **Search & Filter**: Search by caller, callee, hash, or IPFS CID
- **Analytics Charts**: Bar chart showing call distribution per caller
- **QR Code Generator**: Generate QR codes for IPFS links of latest CDRs
- **Responsive Design**: Clean, modern UI built with TailwindCSS
- **Error Handling**: Comprehensive error handling and loading states

## Tech Stack

- **React.js 18** - Frontend framework
- **TailwindCSS** - Utility-first CSS framework
- **Axios** - HTTP client for API calls
- **Chart.js + react-chartjs-2** - Charts and analytics
- **qrcode.react** - QR code generation
- **React Router** - Client-side routing

## Prerequisites

1. **Backend API**: Ensure the FastAPI backend is running on `http://localhost:8000`
2. **Node.js**: Version 16 or higher
3. **npm or yarn**: Package manager

## Installation

1. **Navigate to the React dashboard directory**:
   ```bash
   cd react-dashboard
   ```

2. **Install dependencies**:
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Start the development server**:
   ```bash
   npm start
   # or
   yarn start
   ```

4. **Open your browser** and navigate to `http://localhost:3000`

## Backend API Endpoints

The React frontend connects to these FastAPI endpoints:

- `GET /cdrs` - Fetch all CDRs with IPFS verification
- `GET /cdr/{id}` - Fetch specific CDR by ID
- `POST /store_cdr` - Store new CDR on blockchain
- `GET /record_count` - Get total CDR count
- `GET /verify/{idx}` - Verify CDR hash against IPFS

## Configuration

### Environment Variables

Create a `.env` file in the `react-dashboard` directory:

```env
REACT_APP_API_URL=http://localhost:8000
```

### API Configuration

The API base URL can be configured in `src/api.js`:

```javascript
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  timeout: 10000,
});
```

## Project Structure

```
react-dashboard/
├── public/
│   ├── index.html
│   └── manifest.json
├── src/
│   ├── components/
│   │   ├── StatsCard.js      # Statistics display cards
│   │   ├── CDRTable.js       # Interactive CDR table
│   │   ├── Chart.js          # Analytics charts
│   │   ├── QRCodeDisplay.js  # QR code generator
│   │   └── SearchBar.js      # Search and filter
│   ├── pages/
│   │   └── Dashboard.js      # Main dashboard page
│   ├── api.js               # API service layer
│   ├── App.js               # Main app component
│   ├── index.js             # App entry point
│   └── index.css            # Global styles
├── package.json
├── tailwind.config.js
└── postcss.config.js
```

## Features in Detail

### Dashboard Components

1. **Stats Cards**: Display key metrics with loading states and color-coded status
2. **Search Bar**: Real-time filtering of CDR records
3. **CDR Table**: 
   - Sortable columns
   - Status indicators (verified/mismatch/error)
   - IPFS links (local and public gateways)
   - Responsive design
4. **Analytics Chart**: Bar chart showing call distribution
5. **QR Code Display**: Generate QR codes for IPFS links

### Auto-refresh

The dashboard automatically refreshes every 5 seconds to show the latest data from the blockchain.

### Error Handling

- Network error handling
- Loading states for all components
- User-friendly error messages
- Graceful degradation when backend is unavailable

## Building for Production

```bash
npm run build
# or
yarn build
```

This creates a `build` folder with optimized production files.

## Deployment

The built React app can be deployed to any static hosting service:

- **Netlify**: Drag and drop the `build` folder
- **Vercel**: Connect your Git repository
- **GitHub Pages**: Use `gh-pages` package
- **AWS S3**: Upload build files to S3 bucket

## Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure the FastAPI backend has CORS middleware configured
2. **API Connection**: Check that the backend is running on the correct port
3. **Build Errors**: Clear node_modules and reinstall dependencies

### Backend Setup

Make sure your FastAPI backend (`api_server.py`) includes:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the VoIP Security system and follows the same licensing terms.
