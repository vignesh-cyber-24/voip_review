from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from web3 import Web3
import json, pathlib, hashlib, requests, subprocess, os, time

# ==========================================================
#  FASTAPI INITIALIZATION
# ==========================================================
app = FastAPI(title="VoIP CDR Blockchain API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for frontend access
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================================
#  PATH CONFIGURATION
# ==========================================================
BASE_DIR = pathlib.Path(__file__).resolve().parent
CONTRACT_DIR = BASE_DIR.parent / "voip_contract_project" / "backend"

ABI_FILE = CONTRACT_DIR / "cdr_abi.json"
ADDRESS_FILE = CONTRACT_DIR / "contract_address.txt"
IPFS_MAP_FILE = CONTRACT_DIR / "cdr_ipfs_map.json"
LOCAL_BACKUP = BASE_DIR / "cdr_backup.json"

# ==========================================================
#  LOCAL BACKUP UTILITIES
# ==========================================================
def backup_cdr_locally(cdr):
    """Append each stored CDR to a local JSON file for persistence."""
    try:
        records = []
        if LOCAL_BACKUP.exists():
            with open(LOCAL_BACKUP, "r") as f:
                try:
                    records = json.load(f)
                except json.JSONDecodeError:
                    print("⚠️ Corrupted backup file detected — resetting.")
                    records = []

        # ✅ Safely append serializable version
        records.append(json.loads(json.dumps(cdr, default=str)))

        with open(LOCAL_BACKUP, "w") as f:
            json.dump(records, f, indent=2)

        print(f"💾 Local backup saved ({len(records)} total records).")
    except Exception as e:
        print(f"⚠️ Local backup failed: {e}")

# ==========================================================
#  WEB3 / BLOCKCHAIN INITIALIZATION
# ==========================================================
def load_abi():
    if not ABI_FILE.exists():
        raise FileNotFoundError(f"ABI file missing: {ABI_FILE}")
    with open(ABI_FILE, "r") as f:
        return json.load(f)

def load_address():
    if not ADDRESS_FILE.exists():
        raise FileNotFoundError(f"Contract address missing: {ADDRESS_FILE}")
    with open(ADDRESS_FILE, "r") as f:
        return f.read().strip()

w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
if not w3.is_connected():
    raise Exception("⚠️ Hardhat/Ganache node not connected!")

abi = load_abi()
address = load_address()
account = w3.eth.accounts[0]
contract = w3.eth.contract(address=address, abi=abi)

# ==========================================================
#  IPFS UTILITIES
# ==========================================================
def ipfs_get_json(cid: str):
    """Fetch JSON content from IPFS and handle newline-delimited JSON."""
    urls = [
        f"http://127.0.0.1:8080/ipfs/{cid}",
        f"https://ipfs.io/ipfs/{cid}",
    ]
    for url in urls:
        try:
            r = requests.get(url, timeout=10)
            r.raise_for_status()
            try:
                return r.json()
            except Exception:
                first_line = r.text.splitlines()[0]
                return json.loads(first_line)
        except Exception:
            continue
    raise HTTPException(status_code=502, detail=f"Unable to fetch CID {cid} from IPFS gateways")

def pin_ipfs_cid(cid: str):
    """Pin CID locally so it won’t be garbage-collected."""
    try:
        subprocess.run(["ipfs", "pin", "add", cid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"📌 Pinned CID {cid}")
    except Exception as e:
        print(f"⚠️ Failed to pin CID {cid}: {e}")

# ==========================================================
#  MODELS
# ==========================================================
class CDRRequest(BaseModel):
    caller: str
    callee: str
    duration: int
    status: str
    timestamp: str
    hash: str
    ipfs_cid: str | None = None

# ==========================================================
#  IPFS MAP HANDLING
# ==========================================================
def ensure_ipfs_map():
    """Ensure mapping file exists and migrate old newline format if needed."""
    if not IPFS_MAP_FILE.exists():
        with open(IPFS_MAP_FILE, "w") as f:
            json.dump({}, f)
        print("🆕 Created new IPFS map file.")
        return

    try:
        with open(IPFS_MAP_FILE, "r") as f:
            json.load(f)
    except json.JSONDecodeError:
        print("⚠️ Detected old format — migrating...")
        output = {}
        with open(IPFS_MAP_FILE, "r") as f:
            for line in f:
                try:
                    entry = json.loads(line.strip())
                    output[str(entry["idx"])] = entry["ipfs_cid"]
                except Exception:
                    continue
        with open(IPFS_MAP_FILE, "w") as f:
            json.dump(output, f, indent=2)
        print(f"✅ Migration complete. {len(output)} entries repaired.")

def save_ipfs_mapping(idx: int, cid: str | None):
    """Add or update index → CID mapping safely."""
    if not cid:
        return
    ensure_ipfs_map()
    with open(IPFS_MAP_FILE, "r") as f:
        data = json.load(f)
    data[str(idx)] = cid
    with open(IPFS_MAP_FILE, "w") as f:
        json.dump(data, f, indent=2)
    pin_ipfs_cid(cid)

def get_ipfs_cid_for_idx(idx: int):
    ensure_ipfs_map()
    try:
        with open(IPFS_MAP_FILE, "r") as f:
            data = json.load(f)
            return data.get(str(idx))
    except Exception:
        return None

# ==========================================================
#  ROUTES
# ==========================================================
@app.get("/")
def root():
    return {"message": "VoIP Blockchain API running ✅"}

@app.get("/health")
def health_check():
    """Simple backend status endpoint."""
    try:
        connected = w3.is_connected()
        contract_ok = contract.address is not None
        return {
            "status": "healthy" if connected and contract_ok else "unhealthy",
            "message": "Backend connected to blockchain" if connected else "Blockchain connection failed",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Health check failed: {e}")

# ---------- STORE CDR ----------
@app.post("/store_cdr")
def store_cdr(cdr: CDRRequest):
    """Store new CDR record on blockchain and record optional IPFS CID."""
    try:
        tx = contract.functions.storeCDR(
            cdr.caller, cdr.callee, cdr.duration, cdr.status, cdr.timestamp, cdr.hash
        ).transact({"from": account, "gas": 500_000})

        receipt = w3.eth.wait_for_transaction_receipt(tx)
        idx = contract.functions.recordCount().call() - 1
        save_ipfs_mapping(idx, cdr.ipfs_cid)

        # ✅ Save local JSON backup
        backup_cdr_locally(cdr.dict())

        return {
            "status": "success" if receipt.status == 1 else "failed",
            "tx_hash": receipt.transactionHash.hex(),
            "idx": idx,
            "ipfs_cid": cdr.ipfs_cid,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Blockchain store failed: {e}")

# ---------- GET ALL CDRS ----------
@app.get("/cdrs")
def get_all_cdrs():
    """Return all stored CDRs with optional IPFS mapping."""
    RATE_PER_SECOND = 0.05
    try:
        total = contract.functions.recordCount().call()
        cdrs = []
        for i in range(total):
            try:
                record = contract.functions.getCDR(i).call()
                cdrs.append({
                    "id": i,
                    "caller": record[0],
                    "callee": record[1],
                    "duration": record[2],
                    "status": record[3],
                    "timestamp": record[4],
                    "hash": record[5],
                    "ipfs_cid": get_ipfs_cid_for_idx(i),
                    "billing_cost": round(record[2] * RATE_PER_SECOND, 2)
                })
            except Exception as err:
                print(f"[⚠️ ERROR] Could not fetch record {i}: {err}")
        return {"total": total, "cdrs": cdrs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch CDRs: {e}")

# ---------- VERIFY CDR ----------
@app.get("/verify_cdr/{idx}")
def verify_cdr(idx: int):
    """Verify on-chain vs IPFS hashes."""
    try:
        record = contract.functions.getCDR(idx).call()
        ipfs_cid = get_ipfs_cid_for_idx(idx)
        if not ipfs_cid:
            raise HTTPException(status_code=404, detail="IPFS CID not found for this CDR")

        cdr_data = ipfs_get_json(ipfs_cid)
        caller = str(cdr_data.get("caller", "")).strip()
        callee = str(cdr_data.get("callee", "")).strip()
        timestamp = str(cdr_data.get("timestamp", "")).strip()
        duration = int(cdr_data.get("duration", 0))
        status = str(cdr_data.get("status", "")).strip()

        cdr_string = f"{caller}{callee}{timestamp}{duration}{status}"
        recomputed_hash = hashlib.sha256(cdr_string.encode()).hexdigest()
        onchain_hash = record[5]
        verified = recomputed_hash == onchain_hash

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
            "ipfs_source": f"http://127.0.0.1:8080/ipfs/{ipfs_cid}",
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")

# ---------- BILLING CALCULATION ----------
RATE_PER_SECOND = 0.05

@app.get("/billing/{idx}")
def calculate_billing(idx: int):
    """Calculate call cost only if verified."""
    try:
        verify_result = verify_cdr(idx)
        if not verify_result.get("verified"):
            raise HTTPException(
                status_code=400,
                detail=f"CDR {idx} verification failed. Billing denied.",
            )

        # ✅ Ensure duration is an integer
        duration_raw = verify_result.get("duration", 0)
        try:
            duration = int(duration_raw)
        except (TypeError, ValueError):
            raise HTTPException(status_code=400, detail=f"Invalid duration format: {duration_raw}")

        cost = round(duration * RATE_PER_SECOND, 2)

        return {
            "idx": idx,
            "caller": str(verify_result.get("caller", "")),
            "callee": str(verify_result.get("callee", "")),
            "duration": duration,
            "timestamp": str(verify_result.get("timestamp", "")),
            "status": str(verify_result.get("status", "")),
            "hash": verify_result.get("onchain_hash"),
            "verified": True,
            "rate_per_second": RATE_PER_SECOND,
            "billing_cost": cost,
            "currency": "USD",
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Billing calculation failed: {e}"
        )

# ---------- RESTORE FROM BACKUP ----------
@app.post("/restore_cdrs")
def restore_cdrs():
    """Re-upload all locally backed-up CDRs to blockchain."""
    if not LOCAL_BACKUP.exists():
        raise HTTPException(status_code=404, detail="No local backup file found.")
    try:
        with open(LOCAL_BACKUP, "r") as f:
            data = json.load(f)
        if not data:
            raise HTTPException(status_code=400, detail="Backup file is empty.")

        restored = []
        for cdr in data:
            try:
                tx = contract.functions.storeCDR(
                    cdr["caller"], cdr["callee"], int(cdr["duration"]),
                    cdr["status"], cdr["timestamp"], cdr["hash"]
                ).transact({"from": account, "gas": 500_000})
                receipt = w3.eth.wait_for_transaction_receipt(tx)
                idx = contract.functions.recordCount().call() - 1
                save_ipfs_mapping(idx, cdr.get("ipfs_cid"))
                restored.append({"idx": idx, "status": "restored"})
                print(f"✅ Restored CDR #{idx}")
                time.sleep(0.2)
            except Exception as e:
                print(f"⚠️ Failed to restore record: {e}")
        return {"restored_count": len(restored), "records": restored}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Restore failed: {e}")

# ---------- DEBUG MAP ----------
@app.get("/debug_map")
def debug_map():
    """Show current index → CID mapping."""
    ensure_ipfs_map()
    with open(IPFS_MAP_FILE, "r") as f:
        return json.load(f)

# ==========================================================
#  AUTO MIGRATE OLD MAP FILE ON STARTUP
# ==========================================================
@app.on_event("startup")
def startup_event():
    ensure_ipfs_map()
    print("✅ API startup complete — IPFS map validated.")

    if LOCAL_BACKUP.exists():
        try:
            with open(LOCAL_BACKUP, "r") as f:
                data = json.load(f)
                print(f"🧩 Local backup loaded ({len(data)} stored CDRs).")
        except Exception:
            print("⚠️ Could not read backup file.")
