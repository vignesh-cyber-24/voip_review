import time
import requests
import hashlib

CDR_FILE = "/var/log/asterisk/cdr-csv/Master.csv"
API_URL = "http://localhost:8000/store_cdr"

def tail_file(filename):
    """Follow file for new lines like tail -f."""
    with open(filename, "r") as f:
        f.seek(0, 2)
        while True:
            line = f.readline()
            if not line:
                time.sleep(2)
                continue
            yield line.strip()

def parse_cdr(line):
    """Parse one line from Asterisk Master.csv."""
    fields = line.split(',')
    if len(fields) < 10:
        return None

    caller = fields[0].strip('"')
    callee = fields[1].strip('"')
    timestamp = fields[9].strip('"') if len(fields) > 9 else ""
    duration = fields[12].strip('"') if len(fields) > 12 else "0"
    status = fields[13].strip('"') if len(fields) > 13 else "UNKNOWN"

    # Compute hash for integrity (SHA256 of caller+callee+timestamp+duration+status)
    cdr_str = f"{caller}{callee}{timestamp}{duration}{status}"
    hash_val = hashlib.sha256(cdr_str.encode()).hexdigest()

    return {
        "caller": caller,
        "callee": callee,
        "timestamp": timestamp,
        "duration": duration,
        "status": status,
        "hash": hash_val
    }

def send_to_backend(cdr):
    """Send parsed CDR to FastAPI backend."""
    try:
        response = requests.post(API_URL, json=cdr)
        if response.status_code == 200:
            print(f"[OK] Stored CDR {cdr['caller']} -> {cdr['callee']}")
        else:
            print(f"[ERROR] API response: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"[ERROR] Could not send CDR: {e}")

if __name__ == "__main__":
    print("[LISTENER] Watching for new CDRs...")
    for line in tail_file(CDR_FILE):
        cdr = parse_cdr(line)
        if cdr:
            send_to_backend(cdr)
