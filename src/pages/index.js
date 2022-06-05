import Web3Modal from "web3modal";
import { BigNumber, ethers } from "ethers";
import Pool from "../../artifacts/contracts/Pool.sol/Pool.json";
import Quoter from "@uniswap/v3-periphery/artifacts/contracts/lens/Quoter.sol/Quoter.json";
import Erc20Token from "../abi/Erc20Token.json";

const contractAddress = "0xFc9b87E8370e673e31B222AfD07e150Ea84dE539";
const tokenAddress = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270"; //  TOKEN
const quoterAddress = "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"; // quoter

function HomePage() {
  const quotes = async () => {
    try {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(connection);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(contractAddress, Pool.abi, signer);
      const quoteContract = new ethers.Contract(
        quoterAddress,
        Quoter.abi,
        signer
      );

      const poolData = await contract.getPoolData();
      const { poolTokens, poolTokenPercentages } = poolData;
      const value = ethers.utils.parseUnits("1", 18);

      const outputs = [];

      for (let i = 0; i < poolTokens.length; i++) {
        const inputAmount = value.mul(poolTokenPercentages[i]).div(100);

        const quotedAmountOut =
          await quoteContract.callStatic.quoteExactInputSingle(
            tokenAddress,
            poolTokens[i],
            3000,
            inputAmount.toString(),
            0
          );
        outputs.push(quotedAmountOut.toString());
      }
      console.log(outputs);
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

      const value = ethers.utils.parseUnits("0.1", 18);
      console.log(value.toString());

      const tokenContract = new ethers.Contract(
        tokenAddress,
        Erc20Token.abi,
        signer
      );

      const poolData = await contract.getPoolData();
      console.log(poolData);
      const approval = await tokenContract.approve(contractAddress, value, {
        from: accounts[0],
        gasLimit: 3500000,
      });
      await approval.wait();

      const tx = await contract.initInvestment(accounts[0], value, false, {
        from: accounts[0],
        gasLimit: 3500000,
      });
      console.log(tx);
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

      const tx = await contract.finishInvestment(0, {
        from: accounts[0],
        gasLimit: 3500000,
      });
      console.log(tx);
      await tx.wait();
    } catch (error) {
      console.log(error);
    }
  };

  const setManagerFee = async (e) => {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const accounts = await provider.listAccounts();
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, Pool.abi, signer);
    /*
    const p1 = await contract.pause({
      from: accounts[0],
      gasLimit: 3500000,
    });
    await p1.wait();
    const tx = await contract.setManagerFee(1, {
      from: accounts[0],
      gasLimit: 3500000,
    });
    console.log(tx);
    await tx.wait();
*/
    const fee = await contract.getManagerFee();
    console.log(fee);
    const p2 = await contract.unpause({
      from: accounts[0],
      gasLimit: 3500000,
    });
    await p2.wait();
  };

  const setFeeAddress = async (e) => {
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(connection);
    const accounts = await provider.listAccounts();
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, Pool.abi, signer);
    /*
    const p1 = await contract.pause({
      from: accounts[0],
      gasLimit: 3500000,
    });
    await p1.wait();

 */
    const tx = await contract.setFeeAddress(
      "0x05688530Ee4f82ac928aDB5f591DE1CcF7cEb480",
      {
        from: accounts[0],
        gasLimit: 3500000,
      }
    );
    console.log(tx);
    await tx.wait();

    const fee = await contract.getFeeAddress();
    console.log(fee);
    const p2 = await contract.unpause({
      from: accounts[0],
      gasLimit: 3500000,
    });
    await p2.wait();
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

      <p>
        <button onClick={setManagerFee}>Set Manager Fee</button>
      </p>

      <p>
        <button onClick={setFeeAddress}>Set Fee Address</button>
      </p>
    </div>
  );
}

export default HomePage;
