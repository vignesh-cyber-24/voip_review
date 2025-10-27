import time
import json
import hashlib
import requests

CDR_FILE = "/var/log/asterisk/cdr-csv/Master.csv"
API_URL = "http://127.0.0.1:8000/store_cdr"

# Try IPFS HTTP API (works with 0.30.0+)
IPFS_API_URL = "http://127.0.0.1:5001/api/v0/add"
USE_HTTP_IPFS = True

# ------------------ IPFS Functions ------------------
def ipfs_add_json(data):
    """Uploads JSON to IPFS and returns the CID."""
    try:
        files = {"file": ("cdr.json", json.dumps(data))}
        response = requests.post(IPFS_API_URL, files=files)
        response.raise_for_status()
        cid = response.json()["Hash"]
        print(f"[IPFS ✅] Uploaded to IPFS CID: {cid}")
        return cid
    except Exception as e:
        print(f"[IPFS ERROR] Could not upload: {e}")
        return None


# ------------------ CDR Parsing ------------------
def parse_cdr(line):
    """Parse Asterisk CSV CDR line."""
    fields = line.strip().split(",")
    if len(fields) < 15:
        return None

    try:
        caller = fields[1].strip('"')
        callee = fields[2].strip('"')
        duration_field = fields[13].strip('"')
        duration = int(duration_field) if duration_field.isdigit() else 0
        status = fields[12].strip('"')
        timestamp = fields[9].strip('"')  # call start time

        # Compute unique CDR hash
        cdr_str = f"{caller}{callee}{timestamp}{duration}{status}"
        cdr_hash = hashlib.sha256(cdr_str.encode()).hexdigest()

        return {
            "caller": caller,
            "callee": callee,
            "duration": duration,
            "status": status,
            "timestamp": timestamp,
            "hash": cdr_hash
        }
    except Exception as e:
        print(f"[CDR Parse Error] {e}")
        return None


# ------------------ Backend Push ------------------
def send_to_backend(cdr):
    """Uploads to IPFS first, then sends to FastAPI backend."""
    try:
        cid = ipfs_add_json(cdr)
        if not cid:
            print("[❌] Skipping CDR (IPFS upload failed)")
            return

        cdr["ipfs_cid"] = cid
        r = requests.post(API_URL, json=cdr)
        if r.status_code == 200:
            print(f"[✅ STORED] {cdr['caller']} -> {cdr['callee']} | Tx: {r.json().get('tx_hash')}")
        else:
            print(f"[❌ API ERROR] {r.status_code}: {r.text}")
    except Exception as e:
        print(f"[API Push Error] {e}")


# ------------------ Tail File ------------------
def tail_file(filename):
    """Continuously watch a file for new lines."""
    with open(filename, "r") as f:
        f.seek(0, 2)  # Jump to end
        while True:
            line = f.readline()
            if not line:
                time.sleep(1)
                continue
            yield line


# ------------------ Main ------------------
def main():
    print("[LISTENER] Watching for new CDRs...")

    try:
        for line in tail_file(CDR_FILE):
            cdr = parse_cdr(line)
            if cdr:
                send_to_backend(cdr)
    except KeyboardInterrupt:
        print("\n[EXIT] Listener stopped manually.")
    except Exception as e:
        print(f"[FATAL ERROR] {e}")


if __name__ == "__main__":
    main()
