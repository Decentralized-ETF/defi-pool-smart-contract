import Web3Modal from "web3modal";
import { ethers } from "ethers";
import Pool from "../../artifacts/contracts/Pool.sol/Pool.json";
import Quoter from "@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json";
import Erc20Token from "../abi/Erc20Token.json";

const contractAddress = "0x20439826fc1700834C916Ebe3fdcEA22106bE86A";
const tokenAddress = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
const quoterAddress = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"; // quoter

function HomePage() {
  const quotes = async () => {
    try {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(connection);
      const accounts = await provider.listAccounts();
      const signer = provider.getSigner();
      const contract = new ethers.Contract(contractAddress, Pool.abi, signer);
      const quoteContract = new ethers.Contract(
        quoterAddress,
        Quoter.abi,
        signer
      );
      const poolTokens = await contract.getPoolTokens();
      const tokenDistributions = await contract.getPoolTokensDistributions();
      const value = ethers.utils.parseUnits("0.01", "ether");

      const outputs = [];

      for (let i = 0; i < poolTokens.length; i++) {
        const inputAmount = value.mul(tokenDistributions[i]).div(100);

        const quotedAmountOut =
          await quoteContract.callStatic.quoteExactInputSingle(
            tokenAddress,
            poolTokens[i],
            3000,
            inputAmount.toString(),
            0
          );
        outputs.push(quotedAmountOut);
      }

      const tx = await contract.initSecureInvestment(
        accounts[0],
        value,
        outputs,
        {
          from: accounts[0],
          value,
          gasLimit: 3500000,
        }
      );
      console.log(tx);
      await tx.wait();
    } catch (error) {
      console.log(error);
    }
  };

  const invest = async (e) => {
    try {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(connection);
      const accounts = await provider.listAccounts();
      const signer = provider.getSigner();
      const contract = new ethers.Contract(contractAddress, Pool.abi, signer);

      // const result3 = await contract.getInvestments( accounts[0]);
      // console.log(result3);

      // const result4 = await contract.getInvestment( accounts[0],1);
      // console.log(result4);

      // const result5 = await contract.getPoolData();
      // console.log(result5);

      const tx2 = await contract.finishInvestment(0, {
        from: accounts[0],
        gasLimit: 3500000,
      });

      await tx2.wait();
      console.log(tx2);
      return;

      const result2 = await contract.getPoolTokensDistributions({
        gasLimit: 3500000,
      });
      console.log(result2);

      const result1 = await contract.getPoolTokens({
        gasLimit: 3500000,
      });
      console.log(result1);

      const value = ethers.utils.parseUnits("0.01", "ether");
      console.log(value.toString());

      const tokenContract = new ethers.Contract(
        tokenAddress,
        Erc20Token.abi,
        signer
      );

      const approval = await tokenContract.approve(contractAddress, value, {
        from: accounts[0],
        gasLimit: 3500000,
      });
      await approval.wait();

      const tx = await contract.initInvestment(accounts[0], value, {
        from: accounts[0],
        value,
        gasLimit: 3500000,
      });
      console.log(tx);
      await tx.wait();
    } catch (error) {
      console.log(error);
    }
  };

  const refund = async (e) => {
    try {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(connection);
      const accounts = await provider.listAccounts();
      const signer = provider.getSigner();
      const contract = new ethers.Contract(contractAddress, Pool.abi, signer);

      const tx = await contract.finishInvestment(1, {
        from: accounts[0],
        gasLimit: 3500000,
      });
      console.log(tx);
      await tx.wait();
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <div>
      <p>
        <button onClick={quotes}>Quotes</button>
      </p>

      <p>
        <button onClick={invest}>Invest</button>
      </p>

      <p>
        <button onClick={refund}>Refund</button>
      </p>
    </div>
  );
}

export default HomePage;
