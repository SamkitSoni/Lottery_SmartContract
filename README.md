# Lottery Smart Contract

This project is a decentralized lottery system built using smart contracts and developed by Cyfrin. It leverages Foundry as the development framework for testing and deployment.

## Features
- **Decentralized Lottery**: A fair and transparent lottery system using blockchain technology.
- **Smart Contract-Based**: Ensures security and immutability.
- **Automated Winner Selection**: Uses Chainlink VRF (Verifiable Random Function) to select a winner.
- **Time-Based Draws**: Lottery draws occur at scheduled intervals.
- **Secure Payments**: Winnings are automatically transferred to the winner's address.

## Prerequisites
Before setting up the project, ensure you have the following installed:
- [Foundry](https://github.com/foundry-rs/foundry) (includes `forge` and `cast`)
- Node.js & npm/yarn (for frontend integration, if applicable)
- A wallet such as MetaMask (for deployment & interaction)
- An Ethereum testnet (Goerli, Sepolia, or local node)
- Chainlink VRF & Keepers setup (if using automation)

## Installation
Clone the repository and navigate to the project directory:
```sh
git clone https://github.com/SamkitSoni/Lottery_SmartContract
```
## Configuration
Make .env file
```sh
touch .env
```
Set up environment variables in a `.env` file:
```sh
SEPOLIA_RPC_URL=<YOUR SEPOLIA RPC URL>
ETHERSCAN_API_KEY=<YOUR ETHERSCAN API KEY>
PRIVATE_KEY=<YOUR PRIVATE KEY>
```

## Usage
### Compile Contracts
To compile the smart contract, run:
```sh
make build
```
### Run Tests
To run the test suite, run:
```sh
make test
```
### Deploy Contract
Deploy the smart contract to a test network, run:
```sh
make deploy-sepolia
```
## Security Considerations
- Ensure private keys are not hardcoded or exposed.
- Use testnets before deploying to the mainnet.
- Verify Chainlink integration for fair randomness.

### License
This project is licensed under the MIT License.

### Credits
Developed by Samkit with the Help of [Cyfrin Updraft](https://updraft.cyfrin.io/courses)

### Links
Lets connect on:

[![X](https://img.shields.io/badge/twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://x.com/Samkit_Soni12)
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/samkit-soni-bab741250/)
