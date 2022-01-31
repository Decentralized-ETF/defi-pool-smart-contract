import Web3Modal from "web3modal";
import { ethers } from "ethers";
import TestInvestment from "../../build/contracts/TestInvestment.json";
import Erc20Token from "../abi/Erc20Token.json";

const contractAddress = '0xd8fc7E2526bB9F7E95A3EA4157cb8211fc72e002';
const tokenAddress = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889';
function HomePage() {

    const invest = async (e) => {
        try {
            const web3Modal = new Web3Modal();
            const connection = await web3Modal.connect();
            const provider = new ethers.providers.Web3Provider(connection);
            const accounts = await provider.listAccounts();
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);


            const result1 = await contract.getPoolTokens(
                {
                    gasLimit: 3500000,
                });
            console.log(result1);

            const result2 = await contract.getPoolTokensDistributions(
                {
                    gasLimit: 3500000,
                });
            console.log(result2);

            const value = ethers.utils.parseUnits('0.01', 'ether')
            console.log(value.toString());

            const tokenContract = new ethers.Contract(tokenAddress,
                Erc20Token.abi, signer);

            const approval = await tokenContract.approve(contractAddress,
                value, {
                from: accounts[0],
                gasLimit: 3500000,
            });
            await approval.wait();


            const tx = await contract.initInvestment(
                {
                    from: accounts[0],
                    value,
                    gasLimit: 3500000,
                });
            console.log(tx);
            await tx.wait();
        }
        catch (error) {
            console.log(error);
        }
    }

    const investLocal = async (e) => {
        try {
            // const web3Modal = new Web3Modal();
            //const connection = await web3Modal.connect();
            const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545');
            const accounts = await provider.listAccounts();
            console.log(accounts);
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);
            const value = ethers.utils.parseUnits('5', 'ether')
            console.log(value.toString());

            const tx = await contract.initInvestment(
                {
                    value,
                    gasLimit: 3500000,
                });
            console.log(tx);
            await tx.wait();
        }
        catch (error) {
            console.log(error);
        }
    }

    const getMyInvestmentsLocal = async (e) => {
        try {
            // const web3Modal = new Web3Modal();
            //const connection = await web3Modal.connect();
            const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545');
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);
            const result = await contract.getMyInvestments(
                {
                    gasLimit: 3500000,
                });
            console.log(result);
        }
        catch (error) {
            console.log(error);
        }
    }

    const getInvestDataLocal = async (e) => {
        try {
            const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545');
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);
            const result = await contract.getMyInvestment(0,
                {
                    gasLimit: 3500000,
                });
            console.log(result);
        }
        catch (error) {
            console.log(error);
        }
    }

    const rebalanceLocal = async (e) => {
        try {
            const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545');
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);
            const result = await contract.rebalance('0x5A22204Da599a931f0F8d5bC25D56f91eBFa1050', 0,
                {
                    gasLimit: 3500000,
                });
            console.log(result);
        }
        catch (error) {
            console.log(error);
        }
    }

    const getPoolDataDataLocal = async (e) => {
        try {
            const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:7545');
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);
            const result = await contract.getPoolData();
            console.log(result);
        }
        catch (error) {
            console.log(error);
        }
    }



    const refund = async (e) => {
        try {
            const web3Modal = new Web3Modal();
            const connection = await web3Modal.connect();
            const provider = new ethers.providers.Web3Provider(connection);
            const accounts = await provider.listAccounts();
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                TestInvestment.abi, signer);

            const tx = await contract.finishInvestment(1, {
                from: accounts[0],
                gasLimit: 3500000,
            });
            console.log(tx);
            await tx.wait();
        }
        catch (error) {
            console.log(error);
        }
    }

    return <div>
        <p>
            <button onClick={invest}>
                Invest
            </button>
        </p>
        <p>
            <button onClick={investLocal}>
                Invest Local
            </button>
        </p>
        <p>
            <button onClick={getMyInvestmentsLocal}>
                Get My Investments Local
            </button>
        </p>
        <p>
            <button onClick={getInvestDataLocal}>
                Get Invest Data Local (0)
            </button>
        </p>
        <p>
            <button onClick={rebalanceLocal}>
                Rebalance Local
            </button>
        </p>
        <p>
            <button onClick={getPoolDataDataLocal}>
                Get Pool Data Local
            </button>
        </p>
        <p>
            <button onClick={refund}>
                Refund
            </button>
        </p>
    </div>
}

export default HomePage