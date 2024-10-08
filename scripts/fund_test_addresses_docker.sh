#!/usr/bin/env bash

# Define the path to the faucet.py script
FAUCET_SCRIPT="/home/ubuntu/faucet/faucet.py"

# List of wallet addresses
addresses=(
  "a5e1defb98efe38ebb2d958cee052410247f4c80"
  "fCefe53c7012a075b8a711df391100d9c431c468"
  "a44366bAA26296c1409AD1e284264212029F02f1"
  "c1d91b49A1B3D1324E93F86778C44a03f1063f1b"
  "305F1F471e9baCFF2b3549F9601f9A4BEafc94e1"
  "8B8f5091f8b9817EF69cFC1E8B2f721BafF60DF4"
  "03734276e8f8ab253ff4295e66228DAC936FF5b8"
  "9FE8958A2920985AC7ab8d320fDFaB310135a05B"
  "466f26442DD182C9A1b018Cd06671F9791DdE8Ef"
  "c45994e4098271c3140117ebD5c74C70dd56D9cd"
  "97F272ccfef4026A1F3f0e0E879d514627B84E69"
  "a5e1defb98efe38ebb2d958cee052410247f4c80"
)

# Iterate over the wallet addresses and execute the faucet.py script
for address in "${addresses[@]}"; do
  python3 "$FAUCET_SCRIPT" faucet "$address"
  sleep 15
done
