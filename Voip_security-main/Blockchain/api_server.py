# api_server.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
import json, os, requests, hashlib, pathlib

# ------------------ Initialize App ------------------
app = FastAPI(title="VoIP CDR Blockchain API")

# ------------------ CORS Setup ------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------ Paths ------------------
CONTRACT_DIR = pathlib.Path("/home/vignesh/Documents/VOIP_SECURITY/Voip_security/Voip_security-main/voip_contract_project/backend")

ABI_FILE = CONTRACT_DIR / "cdr_abi.json"
ADDRESS_FILE = CONTRACT_DIR / "contract_address.txt"

# ------------------ Load Contract ------------------
def load_abi():
    if not ABI_FILE.exists():
        raise Exception(f"ABI file not found at {ABI_FILE}")
    with open(ABI_FILE, "r") as f:
        return json.load(f)

def load_address():
    if not ADDRESS_FILE.exists():
        raise Exception(f"Contract address file not found at {ADDRESS_FILE}")
    with open(ADDRESS_FILE, "r") as f:
        return f.read().strip()

# Connect to local Hardhat blockchain
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
if not w3.is_connected():
    raise Exception("⚠️ Hardhat node not connected at http://127.0.0.1:8545")

abi = load_abi()
address = load_address()
account = w3.eth.accounts[0]
contract = w3.eth.contract(address=address, abi=abi)

# ------------------ Data Model ------------------
class CDRRequest(BaseModel):
    caller: str
    callee: str
    hash: str
    ipfs_cid: str | None = None

# ------------------ API Routes ------------------
@app.get("/")
def root():
    return {"message": "VoIP Blockchain API running ✅"}

@app.post("/store_cdr")
def store_cdr(cdr: CDRRequest):
    try:
        tx = contract.functions.storeCDR(cdr.caller, cdr.callee, cdr.hash).transact({
            "from": account,
            "gas": 500_000
        })
        receipt = w3.eth.wait_for_transaction_receipt(tx)
        return {
            "status": "success" if receipt.status == 1 else "failed",
            "tx_hash": receipt.transactionHash.hex()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/cdrs")
def get_all_cdrs():
    try:
        total = contract.functions.recordCount().call()
        cdrs = []

        ipfs_map = {}
        ipfs_file = CONTRACT_DIR / "cdr_ipfs_map.json"
        if ipfs_file.exists():
            try:
                with open(ipfs_file, "r") as f:
                    for line in f:
                        line = line.strip()
                        if line:
                            entry = json.loads(line)
                            ipfs_map[entry["hash"]] = entry.get("ipfs_cid")
            except Exception:
                pass

        for i in range(total):
            caller, callee, h, ts = contract.functions.getCDR(i).call()
            ipfs_cid = ipfs_map.get(h)
            status = "verified" if ipfs_cid else "pending"
            cdrs.append({
                "id": i,
                "caller": caller,
                "callee": callee,
                "hash": h,
                "timestamp": ts,
                "ipfs_cid": ipfs_cid,
                "status": status
            })

        return {"cdrs": cdrs, "total": total}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch: {e}")

@app.get("/verify_cdr/{idx}")
def verify_cdr(idx: int, ipfs_cid: str):
    try:
        caller, callee, chain_hash, ts = contract.functions.getCDR(idx).call()
        url = f"http://127.0.0.1:8080/ipfs/{ipfs_cid}"
        r = requests.get(url, timeout=5)
        r.raise_for_status()
        data = r.json().get("cdr", "")
        recomputed = hashlib.sha256(data.encode()).hexdigest()
        return {
            "verified": recomputed == chain_hash,
            "onchain_hash": chain_hash,
            "computed_hash": recomputed,
            "caller": caller,
            "callee": callee,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
