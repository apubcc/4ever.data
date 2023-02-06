import { ethers, upgrades } from "hardhat";

import { getAddress } from "@ethersproject/address";

import {
  FourEverDataFactory,
  FourEverDataFeeOracle,
} from "../typechain-types/contracts";
import { parseEther } from "@ethersproject/units";

require("hardhat-deploy-ethers");
require("hardhat-deploy");

import * as dotenv from "dotenv";
dotenv.config();

const DAOBeneficiaryAddress = getAddress(
  "0x53e320DC72B233392C87076A71c1A830D565B423"
);

async function main() {
  const FourEverDataTemplateFactory = await ethers.getContractFactory(
    "FourEverDataTemplate"
  );
  const FourEverDataTemplate = await FourEverDataTemplateFactory.deploy();
  await FourEverDataTemplate.deployed();
  console.log(
    "4Ever.Data template deployed at %s",
    FourEverDataTemplate.address
  );

  const FourEverDataFeeOracleFactory = await ethers.getContractFactory(
    "FourEverDataFeeOracle"
  );
  const feeOracle = (await upgrades.deployProxy(
    FourEverDataFeeOracleFactory,
    [parseEther("0.01"), DAOBeneficiaryAddress],
    { kind: "uups" }
  )) as FourEverDataFeeOracle;
  await feeOracle.deployed();
  console.log(
    "4Ever.Data fee oracle factory deployed at %s",
    feeOracle.address
  );

  const signers = await ethers.getSigners();

  const wallets = [];
  const num = 5;
  for (let i = 0; i < num; i++) {
    const wallet = ethers.Wallet.fromMnemonic(
      process.env.MNEMONIC || "",
      `m/44'/60'/0'/0/${i}`
    );
    wallets.push(wallet.connect(ethers.provider));
  }

  const FourEverDataUSDC = await ethers.getContractFactory("FourEverDataUSDC");
  const usdc = await FourEverDataUSDC.deploy();

  console.log(`Signers...`);
  console.log("Owner: ", signers[0].address);
  wallets.forEach((signer, index) => {
    if (index > 5) {
      return;
    }
    console.log(signer.address, signer._isSigner);
  });
  console.log("\n\n");

  await usdc.deployed();

  console.log(`4Ever.Data USDC Deployed:  ${usdc.address}`);

  const FourEverDataFactory = await ethers.getContractFactory(
    "FourEverDataFactory"
  );
  const factory = (await upgrades.deployProxy(
    FourEverDataFactory,
    [FourEverDataTemplate.address, usdc.address, feeOracle.address],
    { kind: "uups" }
  )) as FourEverDataFactory;
  console.log("4Ever.Data factory deployed at %s", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
