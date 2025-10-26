import { ethers, artifacts } from "hardhat"; // ✅ import artifacts from hardhat
import fs from "fs";
import path from "path";

async function main() {
  console.log("⏳ Deploying VoipCDR contract...");

  const VoipCDR = await ethers.getContractFactory("VoipCDR");
  const contract = await VoipCDR.deploy();
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log(`✅ Contract deployed at: ${address}`);

  // Save ABI & address for backend
  const artifact = await artifacts.readArtifact("VoipCDR"); // ✅ use artifacts from Hardhat

  const backendDir = path.join(__dirname, "../backend"); // adjust path if needed
  if (!fs.existsSync(backendDir)) fs.mkdirSync(backendDir);

  fs.writeFileSync(path.join(backendDir, "cdr_abi.json"), JSON.stringify(artifact.abi, null, 2));
  fs.writeFileSync(path.join(backendDir, "contract_address.txt"), address);

  console.log("📦 ABI and address saved to backend folder");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
