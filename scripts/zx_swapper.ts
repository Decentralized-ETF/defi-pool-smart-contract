import {Deployer} from "./classes/Deployer";
import { loadCore } from "./utils";
import hre, { ethers } from 'hardhat'
// import fetch from 'node-fetch';
import querystring from 'querystring';
import axios from 'axios';
import { BigNumber, Contract, utils } from "ethers";
import { AddressZero } from "@ethersproject/constants";
import { buildContractCall, buildMultiswapTx, MetaTransaction, Quote, safeApproveHash } from "./helpers/transaction_builder";
import { Swapper, ZxSwapper } from "../typechain";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { sleep } from "../tests/helpers";
var fs = require('fs');

async function main() {
    const [user] = await ethers.getSigners();
    console.log('NONCE: ', await user.getTransactionCount('pending'));
    const core = await loadCore();
    const swapAmount = 6000000;
    // const deployer = new Deployer();
    console.log('Deploying swapper');
    const factory = await ethers.getContractFactory('ZxSwapper');
    console.log('Got factory');
    // const swapper = await factory.deploy({nonce: await user.getTransactionCount()});
    // console.log('Called deploy();', swapper.deployTransaction.hash);
    // await swapper.deployed();
    // console.log('Deployed');
    // await sleep(10);
    const swapper = await ethers.getContractAt('ZxSwapper', '0x6FB69Cd7deea417a66C9DAd20B3665aE0dA98343');
    console.log('0xSwapper: ', swapper.address);
    // deployer.verify(swapper.address);
    const sellToken = await ethers.getContractAt('@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20', '0x2791bca1f2de4661ed88a30c99a7a9449aa84174');
    console.log('selling token...', sellToken.address);
    await sellToken.approve(swapper.address, swapAmount, {nonce: await user.getTransactionCount()});
    console.log(`Token ${sellToken.address} approved ${swapAmount} to ${swapper.address}`);
    const buyTokens = ['0x2ab4f9ac80f33071211729e45cfc346c1f8446d5', '0x09a84f900205b1ac5f3214d3220c7317fd5f5b77', '0xf50d05a1402d0adafa880d36050736f9f6ee7dee'];
    console.log('buy tokens: ', buyTokens);
    const singleSwapAmount = swapAmount / buyTokens.length;
    const swaps: MetaTransaction[] = [];
    const nonce = await user.getTransactionCount();
    for (const asset of buyTokens) {
        swaps.push(
            await buildSwapTransaction(sellToken.address, asset, singleSwapAmount, nonce, swapper)
        );
    }
    console.log('Swaps created');
    // const multiswapTx = buildMultiswapTx(swapper, swaps.map(s  => s.data), nonce);
    // console.log('Multiswap tx: ', multiswapTx);
    console.log('Tx built');
    const tx = await swapper.multiswap(swaps.map(s  => s.data));
    console.log('Swap tx:', tx.hash)

    // fs.writeFile('tx.json', JSON.stringify(multiswapTx), 'utf8', (err: Error) => {
    //     if (err) throw err;
    //     console.log('complete');
    // });
    // await executeTx(swapper, multiswapTx, [ await safeApproveHash(user1, safe, safeTx, true) ])
    // const tx = await user.sendTransaction({...multiswapTx, gasLimit: 3000000, gasPrice: parseUnits('50', 'gwei'), value: parseEther('0.01')});
    // console.log('Multisend transaction broadcasted to network: ', tx.hash)
    

    

    // await deployer.createPoolWithStorage(Factory, core.swapper, TOKENS)
}

async function buildSwapTransaction(sell: string, buy: string, sellAmount: number, nonce: number, swapper: ZxSwapper): Promise<MetaTransaction> {
    const quote: Quote = await getQuote(sell, buy, sellAmount);
    return buildContractCall(
        swapper, 'fillQuote', [
            sell, buy, quote.allowanceTarget,
            sellAmount, quote.data,
        ], 
    nonce);
}



const getQuote = async (sellToken: string, buyToken: string, amount: number) => {
    const qs = querystring.encode({
      sellToken,
      buyToken,
      sellAmount: amount,
    });
    const quoteUrl = `https://polygon.api.0x.org/swap/v1/quote?${qs}`;
    const response = await axios.get(quoteUrl);
    const quote = await response.data;
  
    return quote;
  };

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
