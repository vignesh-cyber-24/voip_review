from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
import json, pathlib, hashlib, requests

# ------------------ App Init ------------------
app = FastAPI(title="VoIP CDR Blockchain API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ------------------ Paths ------------------
CONTRACT_DIR = pathlib.Path("/home/vignesh/Documents/VOIP_SECURITY/Voip_security/Voip_security-main/voip_contract_project/backend")
ABI_FILE = CONTRACT_DIR / "cdr_abi.json"
ADDRESS_FILE = CONTRACT_DIR / "contract_address.txt"
IPFS_MAP_FILE = CONTRACT_DIR / "cdr_ipfs_map.json"

# ------------------ Load Contract ------------------
def load_abi():
    with open(ABI_FILE, "r") as f:
        return json.load(f)

def load_address():
    with open(ADDRESS_FILE, "r") as f:
        return f.read().strip()

# Connect to Hardhat node
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
if not w3.is_connected():
    raise Exception("⚠️ Hardhat node not connected!")

abi = load_abi()
address = load_address()
account = w3.eth.accounts[0]
contract = w3.eth.contract(address=address, abi=abi)

# ------------------ IPFS Helper ------------------
def ipfs_get_json(cid):
    url = f"http://127.0.0.1:8080/ipfs/{cid}"
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    try:
        return r.json()
    except Exception:
        return json.loads(r.text)

# ------------------ Models ------------------
class CDRRequest(BaseModel):
    caller: str
    callee: str
    duration: int
    status: str
    timestamp: str
    hash: str
    ipfs_cid: str | None = None

# ------------------ Helpers ------------------
def save_ipfs_mapping(idx, cid):
    if not cid:
        return
    with open(IPFS_MAP_FILE, "a") as f:
        f.write(json.dumps({"idx": idx, "ipfs_cid": cid}) + "\n")

def get_ipfs_cid_for_idx(idx):
    try:
        with open(IPFS_MAP_FILE, "r") as f:
            for line in f:
                entry = json.loads(line)
                if entry["idx"] == idx:
                    return entry["ipfs_cid"]
    except FileNotFoundError:
        return None
    return None

# ------------------ Routes ------------------
@app.get("/")
def root():
    return {"message": "VoIP Blockchain API running ✅"}

@app.post("/store_cdr")
def store_cdr(cdr: CDRRequest):
    try:
        tx = contract.functions.storeCDR(
            cdr.caller, cdr.callee, cdr.duration,
            cdr.status, cdr.timestamp, cdr.hash
        ).transact({"from": account, "gas": 500_000})
        receipt = w3.eth.wait_for_transaction_receipt(tx)
        idx = contract.functions.recordCount().call() - 1
        save_ipfs_mapping(idx, cdr.ipfs_cid)
        return {
            "status": "success" if receipt.status == 1 else "failed",
            "tx_hash": receipt.transactionHash.hex(),
            "idx": idx,
            "ipfs_cid": cdr.ipfs_cid
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Blockchain store failed: {e}")

@app.get("/cdrs")
def get_all_cdrs():
    try:
        total = contract.functions.recordCount().call()
        cdrs = []
        for i in range(total):
            try:
                # 🟢 FIXED: Changed getRecord -> getCDR
                record = contract.functions.getCDR(i).call()
                cdrs.append({
                    "id": i,  # manually use index since id not returned
                    "caller": record[0],
                    "callee": record[1],
                    "duration": record[2],
                    "status": record[3],
                    "timestamp": record[4],
                    "hash": record[5],
                    "ipfs_cid": get_ipfs_cid_for_idx(i)
                })
            except Exception as err:
                print(f"[⚠️ ERROR] Could not fetch record {i}: {err}")
        print(f"[✅ INFO] Returning {len(cdrs)} out of {total} records")
        return {"total": total, "cdrs": cdrs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch CDRs: {e}")

# ------------------ Enhanced Verification ------------------
@app.get("/verify_cdr/{idx}")
def verify_cdr(idx: int):
    try:
        # 1️⃣ Fetch record from blockchain
        # 🟢 FIXED: Changed getRecord -> getCDR
        record = contract.functions.getCDR(idx).call()
        ipfs_cid = get_ipfs_cid_for_idx(idx)
        if not ipfs_cid:
            raise HTTPException(status_code=404, detail="IPFS CID not found for this CDR")

        # 2️⃣ Try fetching CDR JSON from IPFS gateway
        try:
            ipfs_url = f"http://127.0.0.1:8080/ipfs/{ipfs_cid}"
            resp = requests.get(ipfs_url, timeout=10)
            resp.raise_for_status()

            # handle raw file (not always pure JSON)
            try:
                cdr_data = resp.json()
            except Exception:
                cdr_data = json.loads(resp.text)
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"IPFS fetch failed: {e}")

        # 3️⃣ Rebuild hash (same logic as listener)
        caller = cdr_data.get("caller", "")
        callee = cdr_data.get("callee", "")
        timestamp = cdr_data.get("timestamp", "")
        duration = int(cdr_data.get("duration", 0))
        status = cdr_data.get("status", "")

        cdr_string = f"{caller}{callee}{timestamp}{duration}{status}"
        recomputed_hash = hashlib.sha256(cdr_string.encode()).hexdigest()
        onchain_hash = record[5]  # 🟢 fixed index (hash is last item)

        # 4️⃣ Compare hashes
        verified = (recomputed_hash == onchain_hash)

        # 5️⃣ Return structured verification data
        return {
            "verified": verified,
            "onchain_hash": onchain_hash,
            "computed_hash": recomputed_hash,
            "caller": record[0],
            "callee": record[1],
            "duration": record[2],
            "status": record[3],
            "timestamp": record[4],
            "ipfs_cid": ipfs_cid,
            "ipfs_source": f"http://127.0.0.1:8080/ipfs/{ipfs_cid}"
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")
