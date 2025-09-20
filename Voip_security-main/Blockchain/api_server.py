# api_server.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import requests
import os
from web3 import Web3

# ---------- FastAPI ----------
app = FastAPI(title="VoIP CDR Blockchain API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- Helpers to load ABI & Address ----------
def load_abi():
    with open("cdr_abi.json", "r") as f:
        return json.load(f)

def load_address():
    with open("contract_address.txt", "r") as f:
        return f.read().strip()

# ---------- Blockchain Setup ----------
abi = load_abi()
address = load_address()

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))  # Ganache/local node
account = w3.eth.accounts[0]
contract = w3.eth.contract(address=address, abi=abi)

# ---------- Models ----------
class CDRRequest(BaseModel):
    caller: str
    callee: str
    hash: str
    ipfs_cid: str | None = None   # optional IPFS CID

# ---------- API Routes ----------
@app.get("/")
def root():
    return {"message": "VoIP CDR Blockchain API is running 🚀"}

@app.post("/store_cdr")
def store_cdr(cdr: CDRRequest):
    """Store a CDR on the blockchain"""
    tx = contract.functions.storeCDR(cdr.caller, cdr.callee, cdr.hash).transact({
        "from": account,
        "gas": 300000
    })
    receipt = w3.eth.wait_for_transaction_receipt(tx)
    return {
        "status": "success" if receipt.status == 1 else "failed",
        "tx_hash": receipt.transactionHash.hex()
    }

@app.get("/record_count")
def record_count():
    """Get total number of CDRs stored"""
    return {"count": contract.functions.recordCount().call()}

@app.get("/cdr/{idx}")
def get_cdr(idx: int):
    """Fetch a specific CDR from blockchain by index"""
    caller, callee, h, ts = contract.functions.getCDR(idx).call()
    return {"caller": caller, "callee": callee, "hash": h, "timestamp": ts}

@app.get("/verify/{idx}")
def verify_cdr(idx: int, ipfs_cid: str):
    """
    Verify if the CDR on blockchain matches the IPFS copy
    Pass CDR index and IPFS CID
    """
    # Fetch blockchain record
    caller, callee, chain_hash, ts = contract.functions.getCDR(idx).call()

    # Fetch from IPFS
    url = f"https://ipfs.io/ipfs/{ipfs_cid}"
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        data = r.json().get("cdr", "")
    except Exception as e:
        return {"status": "error", "reason": f"ipfs-fetch-failed: {e}"}

    # Recompute hash
    import hashlib
    recomputed = hashlib.sha256(data.encode()).hexdigest()

    if recomputed == chain_hash:
        return {"status": "verified", "caller": caller, "callee": callee, "hash": chain_hash}
    else:
        return {"status": "mismatch", "onchain_hash": chain_hash, "recomputed_hash": recomputed}

# ---------- Helper Functions ----------
def load_ipfs_mapping():
    """Load IPFS mapping from file"""
    mapping_file = "cdr_ipfs_map.json"
    if not os.path.exists(mapping_file):
        return {}

    mapping = {}
    try:
        with open(mapping_file, "r") as f:
            for line in f:
                line = line.strip()
                if line:
                    data = json.loads(line)
                    mapping[data["hash"]] = data["ipfs_cid"]
    except Exception as e:
        print(f"Error loading IPFS mapping: {e}")
    return mapping

def verify_cdr_with_ipfs(idx, caller, callee, chain_hash, ipfs_cid):
    """Verify a CDR against IPFS data"""
    if not ipfs_cid:
        return "no_ipfs"

    # Try local IPFS first, then public gateway
    urls = [
        f"http://127.0.0.1:8080/ipfs/{ipfs_cid}",
        f"https://ipfs.io/ipfs/{ipfs_cid}"
    ]

    for url in urls:
        try:
            r = requests.get(url, timeout=5)
            r.raise_for_status()
            data = r.json().get("cdr", "")

            # Recompute hash
            import hashlib
            recomputed = hashlib.sha256(data.encode()).hexdigest()

            if recomputed == chain_hash:
                return "verified"
            else:
                return "mismatch"
        except Exception:
            continue

    return "error"

@app.get("/cdrs")
def get_all_cdrs():
    """Fetch all CDRs from blockchain with IPFS verification"""
    try:
        total_records = contract.functions.recordCount().call()
        ipfs_mapping = load_ipfs_mapping()

        cdrs = []
        for i in range(total_records):
            try:
                caller, callee, chain_hash, timestamp = contract.functions.getCDR(i).call()
                ipfs_cid = ipfs_mapping.get(chain_hash, None)

                # Verify CDR if IPFS CID is available
                status = verify_cdr_with_ipfs(i, caller, callee, chain_hash, ipfs_cid)

                cdr_data = {
                    "id": i,
                    "caller": caller,
                    "callee": callee,
                    "hash": chain_hash,
                    "timestamp": timestamp,
                    "ipfs_cid": ipfs_cid,
                    "status": status,
                    "ipfs_local_url": f"http://127.0.0.1:8080/ipfs/{ipfs_cid}" if ipfs_cid else None,
                    "ipfs_public_url": f"https://ipfs.io/ipfs/{ipfs_cid}" if ipfs_cid else None
                }
                cdrs.append(cdr_data)
            except Exception as e:
                print(f"Error fetching CDR {i}: {e}")
                continue

        return {"cdrs": cdrs, "total": total_records}
    except Exception as e:
        return {"error": f"Failed to fetch CDRs: {e}", "cdrs": [], "total": 0}

