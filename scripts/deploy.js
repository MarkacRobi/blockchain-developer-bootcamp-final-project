// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is avaialble in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Variables used in deployment
  const governorContractName = "RobiGovernor";
  const tokenContractName = "RobiToken";
  const tokenName = "RobiToken";
  const tokenSymbol = "RTK";
  const initialRtkSupply = 10000;

  const RobiToken = await ethers.getContractFactory("RobiToken");
  const robiToken = await RobiToken.deploy(initialRtkSupply, tokenName, tokenSymbol);
  await robiToken.deployed();



  const RobiGovernor = await ethers.getContractFactory(governorContractName);
  const robiGovernor = await RobiGovernor.deploy(robiToken.address, governorContractName);
  await robiGovernor.deployed();

  console.log("RobiToken address:", robiToken.address);
  console.log("RobiGovernor address:", robiGovernor.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(robiToken, tokenContractName);
  console.log("Saved RobiToken contract to the frontend files.");
  saveFrontendFiles(robiGovernor, governorContractName);
  console.log("Saved RobiGovernance contract to the frontend files.");
}

function saveFrontendFiles(token, name) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../frontend/src/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + `/${name.toLowerCase()}-contract-address.json`,
    JSON.stringify({ [name]: token.address }, undefined, 2)
  );

  const RobiTokenArtifact = artifacts.readArtifactSync(name);

  fs.writeFileSync(
    contractsDir + `/${name}.json`,
    JSON.stringify(RobiTokenArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
