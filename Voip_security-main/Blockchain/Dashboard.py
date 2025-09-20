# Dashboard.py
import csv
import hashlib
import time
import os
import json
from datetime import datetime
from web3 import Web3
import streamlit as st
import subprocess
import requests
from solcx import compile_standard, install_solc, set_solc_version, get_installed_solc_versions
from streamlit_autorefresh import st_autorefresh

# ------------------------------
# 1️⃣ Solidity Compiler Setup
# ------------------------------
SOLC_VERSION = "0.8.20"
if SOLC_VERSION not in get_installed_solc_versions():
    install_solc(SOLC_VERSION)
set_solc_version(SOLC_VERSION)

# ------------------------------
# 2️⃣ Solidity Contract
# ------------------------------
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

# ------------------------------
# 3️⃣ Connect to Ganache
# ------------------------------
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
account = w3.eth.accounts[0]

CONTRACT_FILE = "contract_address.txt"
MAPPING_FILE = "cdr_ipfs_map.json"
LOG_FILE = "cdr_pipeline.log"

# ------------------------------
# 4️⃣ Deploy or Use Existing Contract
# ------------------------------
if os.path.exists(CONTRACT_FILE):
    with open(CONTRACT_FILE, "r") as f:
        CONTRACT_ADDRESS = f.read().strip()
    contract = w3.eth.contract(address=w3.to_checksum_address(CONTRACT_ADDRESS), abi=abi)
    st.success(f"Using existing contract at: {CONTRACT_ADDRESS}")
else:
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    tx_hash = Contract.constructor().transact({"from": account, "gas": 5000000})
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    CONTRACT_ADDRESS = receipt.contractAddress
    with open(CONTRACT_FILE, "w") as f:
        f.write(CONTRACT_ADDRESS)
    contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=abi)
    st.success(f"Contract deployed at: {CONTRACT_ADDRESS}")

# ------------------------------
# 5️⃣ Helpers
# ------------------------------
CDR_FILE = "/var/log/asterisk/cdr-csv/Master.csv"

def sha256_hex(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest()

def normalize(row):
    src = row[1]
    dst = row[2]
    start = row[9] if len(row) > 9 else ""
    end = row[11] if len(row) > 11 else ""
    duration = row[12] if len(row) > 12 else ""
    canon = json.dumps({
        "caller": src,
        "callee": dst,
        "start": start,
        "end": end,
        "duration": duration
    }, separators=(',', ':'), sort_keys=True)
    return canon, src, dst

def store_offchain_ipfs(canon_str):
    fname = f"cdr_{int(time.time()*1000)}.json"
    with open(fname, "w") as f:
        json.dump({"cdr": canon_str}, f)
    try:
        cid = subprocess.check_output(["ipfs", "add", "-q", fname]).decode().strip()
    finally:
        os.remove(fname)
    return cid

def verify_offchain_vs_onchain_from_ipfs(cid, chain_hash):
    url = f"http://127.0.0.1:8080/ipfs/{cid}"
    try:
        r = requests.get(url, timeout=5)
        r.raise_for_status()
        data = r.json()["cdr"]
        recomputed = sha256_hex(data)
        if recomputed == chain_hash:
            return True, "verified"
        else:
            return False, "mismatch"
    except Exception as e:
        return False, f"ipfs-fetch-error:{e}"

def log_cdr(cdr_info, status):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"{timestamp} | Caller: {cdr_info['caller']} -> {cdr_info['callee']} | Hash: {cdr_info['hash']} | IPFS CID: {cdr_info['ipfs_cid']} | Status: {status}\n"
    with open(LOG_FILE, "a") as f:
        f.write(log_line)

# ------------------------------
# 6️⃣ Streamlit UI
# ------------------------------
st.title("🛰 CDR Blockchain + IPFS Dashboard")

# 🔄 Auto-refresh every 5 seconds
st_autorefresh(interval=5000, key="cdr_refresh")

total_records = contract.functions.recordCount().call()
st.info(f"Total CDRs on blockchain: {total_records}")

# ------------------------------
# 7️⃣ Display Latest CDRs
# ------------------------------
if os.path.exists(MAPPING_FILE):
    with open(MAPPING_FILE, "r") as f:
        lines = f.readlines()
    if lines:
        cdrs = [json.loads(line) for line in lines]
        st.table(cdrs[-5:])  # Show last 5 CDRs
