import Web3Modal from "web3modal";
import { ethers} from "ethers";
import Investment from "../../build/contracts/Investment.json";
import Erc20Token from "../abi/Erc20Token.json";

const contractAddress = '0x0Fab59613d0c36f710F45ce73E248ebA3Aa999B7';
const tokenAddress = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270';
function HomePage() {

    const invest = async (e) => {
        try {
            const web3Modal = new Web3Modal();
            const connection = await web3Modal.connect();
            const provider = new ethers.providers.Web3Provider(connection);
            const accounts = await provider.listAccounts();
            const signer = provider.getSigner();
            const contract = new ethers.Contract(contractAddress,
                Investment.abi, signer);
            const value = ethers.utils.parseUnits('0.2', 'ether')
            console.log(value.toString());

            const tokenContract = new ethers.Contract(tokenAddress,
                Erc20Token.abi, signer);

            const approval = await tokenContract.approve(contractAddress,
                value,{
                    from: accounts[0],
                    gasLimit: 3500000,
                });
            await approval.wait();


            const tx = await contract.initInvestment(
                { from: accounts[0],
                    value,
                gasLimit: 3500000,
                });
            console.log(tx);
            await tx.wait();
        }
        catch(error){
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
                Investment.abi, signer);

            const tx = await contract.finishInvestment(1,{
                from :accounts[0],
                gasLimit: 3500000,
            });
            console.log(tx);
            await tx.wait();
        }
        catch(error){
            console.log(error);
        }
    }

    return <div>

        <button onClick={invest}>
            Invest
        </button>

        <p>
            <button onClick={refund}>
                Refund
            </button>
        </p>
    </div>
}

export default HomePage