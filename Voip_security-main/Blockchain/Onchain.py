# extended_cdr_pipeline_auto_full.py
import csv, hashlib, time, os, json, subprocess
from web3 import Web3
from datetime import datetime
import requests
from solcx import compile_standard, install_solc, set_solc_version, get_installed_solc_versions

# ---------- Install & set Solidity compiler safely ----------
SOLC_VERSION = "0.8.20"

if SOLC_VERSION not in get_installed_solc_versions():
    print(f"🔧 Installing solc {SOLC_VERSION} ...")
    install_solc(SOLC_VERSION)
else:
    print(f"✅ solc {SOLC_VERSION} already installed")

set_solc_version(SOLC_VERSION)

# ---------- Solidity contract ----------
CONTRACT_SOURCE = """
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VoipCDR {
    struct CDR {
        string caller;
        string callee;
        string hash;
        uint256 timestamp;
    }

    CDR[] public cdrs;

    function storeCDR(string memory caller, string memory callee, string memory hash) public {
        cdrs.push(CDR(caller, callee, hash, block.timestamp));
    }

    function recordCount() public view returns (uint256) {
        return cdrs.length;
    }

    function getCDR(uint256 idx) public view returns (string memory, string memory, string memory, uint256) {
        CDR memory c = cdrs[idx];
        return (c.caller, c.callee, c.hash, c.timestamp);
    }
}
"""

compiled_sol = compile_standard({
    "language": "Solidity",
    "sources": {"VoipCDR.sol": {"content": CONTRACT_SOURCE}},
    "settings": {"outputSelection": {"*": {"*": ["abi", "evm.bytecode"]}}}
})

abi = compiled_sol["contracts"]["VoipCDR.sol"]["VoipCDR"]["abi"]
bytecode = compiled_sol["contracts"]["VoipCDR.sol"]["VoipCDR"]["evm"]["bytecode"]["object"]

# ---------- Web3 setup ----------
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))  # Ganache/local node
account = w3.eth.accounts[0]

# ---------- Deploy contract if not deployed ----------
CONTRACT_FILE = "contract_address.txt"

if os.path.exists(CONTRACT_FILE):
    with open(CONTRACT_FILE, "r") as f:
        CONTRACT_ADDRESS = f.read().strip()
    contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=abi)
    print("✅ Using existing contract at:", CONTRACT_ADDRESS)
else:
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    tx_hash = Contract.constructor().transact({"from": account, "gas": 5000000})
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    CONTRACT_ADDRESS = receipt.contractAddress
    with open(CONTRACT_FILE, "w") as f:
        f.write(CONTRACT_ADDRESS)
    contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=abi)
    print("✅ Contract deployed at:", CONTRACT_ADDRESS)

# ---------- Logs & mapping ----------
LOG_FILE = "cdr_pipeline.log"
MAPPING_FILE = "cdr_ipfs_map.json"

# ---------- Helpers ----------
def sha256_hex(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest()

def store_offchain_ipfs(canon_str):
    fname = f"cdr_{int(time.time()*1000)}.json"
    with open(fname, "w") as f:
        json.dump({"cdr": canon_str}, f)
    try:
        cid = subprocess.check_output(["ipfs", "add", "-q", fname]).decode().strip()
    finally:
        os.remove(fname)
    return cid

def log_cdr(cdr_info, status):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"{timestamp} | Caller: {cdr_info.get('caller','-')} -> {cdr_info.get('callee','-')} | Hash: {cdr_info.get('hash','-')} | IPFS CID: {cdr_info.get('ipfs_cid','-')} | Status: {status}\n"
    with open(LOG_FILE, "a") as f:
        f.write(log_line)

def display_dashboard(total_records, last_cdr=None):
    os.system('clear')
    print("🛰  CDR Blockchain Dashboard")
    print("="*60)
    print(f"Total CDRs on blockchain: {total_records}")
    if last_cdr:
        print(f"Last CDR Caller->Callee: {last_cdr['caller']}->{last_cdr['callee']}")
        print(f"Hash: {last_cdr['hash']}")
        print(f"IPFS CID: {last_cdr['ipfs_cid']}")
        print(f"Status: {last_cdr['status']}")
    print("="*60)

# ---------- Normalize & Tail CSV ----------
CDR_FILE = "/var/log/asterisk/cdr-csv/Master.csv"

def normalize(row):
    src = row[1]
    dst = row[2]
    start = row[9] if len(row) > 9 else ""
    end = row[11] if len(row) > 11 else ""
    duration = row[12] if len(row) > 12 else ""
    cost = row[13] if len(row) > 13 else 0
    call_type = row[14] if len(row) > 14 else "VoIP"
    network = row[15] if len(row) > 15 else "unknown"
    canon = json.dumps({
        "caller": src,
        "callee": dst,
        "start": start,
        "end": end,
        "duration": duration,
        "cost": cost,
        "call_type": call_type,
        "network": network
    }, separators=(',', ':'), sort_keys=True)
    return canon, src, dst

def tail_csv(path):
    with open(path, "r") as f:
        f.seek(0, os.SEEK_END)
        while True:
            pos = f.tell()
            line = f.readline()
            if not line:
                time.sleep(0.5)
                f.seek(pos)
                continue
            yield next(csv.reader([line]))

# ---------- Verify via IPFS ----------
def verify_offchain_vs_onchain_from_ipfs(cid, chain_hash):
    url = f"https://ipfs.io/ipfs/{cid}"
    try:
        r = requests.get(url)
        r.raise_for_status()
        data = r.json()["cdr"]
    except Exception as e:
        return False, f"ipfs-fetch-error:{e}"
    recomputed = sha256_hex(data)
    if recomputed == chain_hash:
        return True, "verified"
    return False, "mismatch"

# ---------- Main Loop ----------
print("📡 Watching Asterisk CDRs in real-time... (Ctrl+C to stop)")

try:
    for row in tail_csv(CDR_FILE):
        try:
            canon, caller, callee = normalize(row)
            h = sha256_hex(canon)
            total = contract.functions.recordCount().call()
            print(f"\n☎ New CDR {caller}->{callee}, hash={h}")

            # Store on IPFS
            ipfs_cid = store_offchain_ipfs(canon)
            print("Stored to IPFS CID:", ipfs_cid)

            # Store hash on-chain
            tx = contract.functions.storeCDR(caller, callee, h).transact({
                "from": account,
                "gas": 300000
            })
            receipt = w3.eth.wait_for_transaction_receipt(tx)
            last_cdr = None
            if receipt.status == 1:
                total = contract.functions.recordCount().call()
                latest_id = total - 1
                bc_caller, bc_callee, bc_hash, ts = contract.functions.getCDR(latest_id).call()
                ok, status = verify_offchain_vs_onchain_from_ipfs(ipfs_cid, bc_hash)
                last_cdr = {"caller": bc_caller, "callee": bc_callee, "hash": bc_hash, "ipfs_cid": ipfs_cid, "status": status}

                # Save mapping locally
                with open(MAPPING_FILE, "a") as f:
                    f.write(json.dumps({"hash": h, "ipfs_cid": ipfs_cid}) + "\n")

                log_cdr(last_cdr, status)
                print(f"On-chain stored, verification={status}")
            else:
                print("⚠ Transaction failed")

            display_dashboard(total_records=total, last_cdr=last_cdr)

        except Exception as e:
            print("Row error:", e)

except KeyboardInterrupt:
    print("\n🛑 Stopped monitoring.")
