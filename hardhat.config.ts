import '@nomicfoundation/hardhat-toolbox';
import dotenv from 'dotenv';
import * as fs from 'fs';
import 'hardhat-deploy';
import 'hardhat-ignore-warnings';
import 'hardhat-preprocessor';
import { TASK_PREPROCESS } from 'hardhat-preprocessor';
import type { HardhatUserConfig, extendProvider } from 'hardhat/config';
import { task } from 'hardhat/config';
import type { NetworkUserConfig } from 'hardhat/types';
import { resolve } from 'path';
import * as path from 'path';

import CustomProvider from './CustomProvider';
import './tasks/accounts';
import './tasks/getEthereumAddress';
import './tasks/mint';
import './tasks/taskDeploy';
import './tasks/taskGatewayRelayer';
import './tasks/taskIdentity';
import './tasks/taskTFHE';

extendProvider(async (provider, config, network) => {
  const newProvider = new CustomProvider(provider);
  return newProvider;
});

// Function to recursively get all .sol files in a folder
function getAllSolidityFiles(dir: string, fileList: string[] = []): string[] {
  fs.readdirSync(dir).forEach((file) => {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      getAllSolidityFiles(filePath, fileList);
    } else if (filePath.endsWith('.sol')) {
      fileList.push(filePath);
    }
  });
  return fileList;
}

task('compile:specific', 'Compiles only the specified contract')
  .addParam('contract', "The contract's path")
  .setAction(async ({ contract }, hre) => {
    hre.config.paths.sources = contract;
    await hre.run('compile');
  });

task('coverage-mock', 'Run coverage after running pre-process task').setAction(async function (args, env) {
  const examplesPath = path.join(env.config.paths.root, 'examples/');
  const solidityFiles = getAllSolidityFiles(examplesPath);
  const originalContents: Record<string, string> = {};
  solidityFiles.forEach((filePath) => {
    originalContents[filePath] = fs.readFileSync(filePath, { encoding: 'utf8' });
  });

  try {
    await env.run(TASK_PREPROCESS);
    await env.run('coverage');
  } finally {
    for (const filePath in originalContents) {
      fs.writeFileSync(filePath, originalContents[filePath], { encoding: 'utf8' });
    }
  }
});

// Load environment variables
dotenv.config({ path: resolve(__dirname, './.env') });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error('Please set your MNEMONIC in a .env file');
}

// Retrieve chain ID and RPC URL from the .env file
const chainId = Number(process.env.CHAIN_ID);
const rpcUrl = process.env.RPC_URL;

if (!chainId || !rpcUrl) {
  throw new Error('Please set your CHAIN_ID and RPC_URL in a .env file');
}

const config: HardhatUserConfig = {
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => line,
    }),
  },
  defaultNetwork: 'custom', // Change this to your desired default network name
  namedAccounts: {
    deployer: 0,
  },
  mocha: {
    timeout: 500000,
  },
  gasReporter: {
    currency: 'USD',
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: './examples',
  },
  networks: {
    custom: {
      url: rpcUrl,
      chainId: chainId,
      accounts: {
        count: 10,
        mnemonic,
        path: "m/44'/60'/0'/0",
      },
    },
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './examples',
    tests: './test',
  },
  solidity: {
    version: '0.8.24',
    settings: {
      metadata: {
        bytecodeHash: 'none',
      },
      optimizer: {
        enabled: true,
        runs: 800,
      },
      evmVersion: 'cancun',
    },
  },
  warnings: {
    '*': {
      'transient-storage': false,
    },
  },
  typechain: {
    outDir: 'types',
    target: 'ethers-v6',
  },
};

export default config;
