
import querystring from 'querystring';
import axios from 'axios';
import { BigNumber, BigNumberish, Contract, Signer, utils } from "ethers";
import { AddressZero } from "@ethersproject/constants";

export type Quote = {
  chainId: number,
  price: string,
  guaranteedPrice: string,
  estimatedPriceImpact: string,
  to: string,
  data: string,
  value: string
  gas: string,
  estimatedGas: string,
  gasPrice: string,
  protocolFee: string,
  minimumProtocolFee: string,
  buyAmount: string,
  sellAmount: string,
  allowanceTarget: string,
}

export const EIP712_SAFE_TX_TYPE = {
  // "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
  SafeTx: [
      { type: "address", name: "to" },
      { type: "uint256", name: "value" },
      { type: "bytes", name: "data" },
      { type: "uint8", name: "operation" },
      { type: "uint256", name: "safeTxGas" },
      { type: "uint256", name: "baseGas" },
      { type: "uint256", name: "gasPrice" },
      { type: "address", name: "gasToken" },
      { type: "address", name: "refundReceiver" },
      { type: "uint256", name: "nonce" },
  ]
}

export interface SafeSignature {
  signer: string,
  data: string
}

export interface MetaTransaction {
  to: string,
  value: string | number | BigNumber,
  data: string,
  operation: number,
}

export interface SafeTransaction extends MetaTransaction {
  nonce: string | number
}


const encodeMetaTransaction = (tx: MetaTransaction): string => {
  const data = utils.arrayify(tx.data);
  const encoded = utils.solidityPack(
      ["uint8", "address", "uint256", "uint256", "bytes"],
      [tx.operation, tx.to, tx.value, data.length, data]
  )
  return encoded.slice(2)
}

export const calculateSafeTransactionHash = (safe: Contract, safeTx: SafeTransaction, chainId: BigNumberish): string => {
  return utils._TypedDataEncoder.hash({ verifyingContract: safe.address, chainId }, EIP712_SAFE_TX_TYPE, safeTx)
}

export const safeApproveHash = async (signer: Signer, safe: Contract, safeTx: SafeTransaction): Promise<SafeSignature> => {
  const signerAddress = await signer.getAddress()
  return {
      signer: signerAddress,
      data: "0x000000000000000000000000" + signerAddress.slice(2) + "0000000000000000000000000000000000000000000000000000000000000000" + "01"
  }
}

export const executeTx = async (safe: Contract, safeTx: SafeTransaction, signatures: SafeSignature[]): Promise<any> => {
  const signatureBytes = buildSignatureBytes(signatures)
  return safe.execTransaction(safeTx.to, safeTx.value, safeTx.data, safeTx.operation, signatureBytes)
}

export const buildSignatureBytes = (signatures: SafeSignature[]): string => {
  signatures.sort((left, right) => left.signer.toLowerCase().localeCompare(right.signer.toLowerCase()))
  let signatureBytes = "0x"
  for (const sig of signatures) {
      signatureBytes += sig.data.slice(2)
  }
  return signatureBytes
}

export const encodeSwaps = (txs: MetaTransaction[]): string => {
  return "0x" + txs.map((tx) => encodeMetaTransaction(tx)).join("")
}

export const buildMultiswapTx = (multiSend: Contract, txs: string[], nonce: number, overrides?: Partial<SafeTransaction>): SafeTransaction => {
  return buildContractCall(multiSend, "multiswap", [txs], nonce, 0, overrides)
}

export const buildContractCall = (contract: Contract, method: string, params: any[], nonce: number, operation=0, overrides?: Partial<SafeTransaction>): SafeTransaction => {
  const data = contract.interface.encodeFunctionData(method, params)
  return buildSafeTransaction(Object.assign({
      to: contract.address,
      data,
      nonce,
      operation,
  }, overrides))
}

export const buildSafeTransaction = (template: {
  to: string, value?: BigNumber | number | string, data?: any, operation?: number,
  nonce: number
}): SafeTransaction => {
  return {
      to: template.to,
      value: template.value || 0,
      data: template.data,
      operation: template.operation || 0,
      nonce: template.nonce
  }
}
