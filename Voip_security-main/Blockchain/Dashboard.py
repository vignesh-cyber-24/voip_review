from web3 import Web3
import json, solcx, os, time

# Connect to local Hardhat node
ganache_url = "http://127.0.0.1:8545"
w3 = Web3(Web3.HTTPProvider(ganache_url))

if not w3.is_connected():
    print("❌ Error: Could not connect to Hardhat node. Make sure 'npx hardhat node' is running.")
    exit(1)
print("✅ Connected to Hardhat node")

# Compile contract
contract_path = "/home/vignesh/Documents/VOIP_SECURITY/Voip_security/Voip_security-main/voip_contract_project/contracts/VoipCDR.sol"
compiled_sol = solcx.compile_files(
    [contract_path],
    output_values=["abi", "bin"],
    solc_version="0.8.28",

)
contract_id, contract_interface = compiled_sol.popitem()
abi = contract_interface["abi"]
bytecode = contract_interface["bin"]

# Deploy contract
account = w3.eth.accounts[0]
VoipCDR = w3.eth.contract(abi=abi, bytecode=bytecode)
print("🚀 Deploying contract from:", account)

tx_hash = VoipCDR.constructor().transact({"from": account})
print("⏳ Waiting for transaction confirmation...")
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
contract_address = tx_receipt.contractAddress

print(f"✅ Contract deployed successfully at: {contract_address}")

# Save ABI and address
with open("contract_address.txt", "w") as f:
    f.write(contract_address)

with open("VoipCDR.json", "w") as f:
    json.dump({"abi": abi}, f)

print("📄 contract_address.txt and VoipCDR.json updated.")
