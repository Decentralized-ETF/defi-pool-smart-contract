//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
import "..\libs\KedrLib.sol";

contract KedrStorage {
    address public owner = msg.sender;
    address public latestVersion;

    uint256 public minInvestmentLimit = 0;

    address public feeRecepient = msg.sender;

    uint24 public successFeeInBp = 100;
    uint256 public totalSuccessFeeCollected = 0;

    uint24 public managerFeeInBp = 100;
    uint256 public totalManagerFeeCollected = 0;

    uint24[] public poolTokenDistributionsInBP;
    address[] public poolTokens;

    uint256[] public poolTokenBalances;
    uint256 public totalReceivedEntryAsset = 0;

    modifier onlyLatestVersion() {
        require(msg.sender == latestVersion);
        _;
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner);
        latestVersion = _newVersion;
    }

    function getInvestment(address _investor, uint16 _investmentId)
        public
        view
        returns (InvestmentData memory)
    {
        require(_investmentId >= 0, "invalid investment Id");

        return investmentDataByUser[_investor][_investmentId];
    }

    function getInvestments(address _investor)
        public
        view
        returns (InvestmentData[] memory)
    {
        return investmentDataByUser[_investor];
    }

    function setMinInvestmentLimit(uint256 _minInvestmentLimit) external onlyLatestVersion {
        minInvestmentLimit = _minInvestmentLimit;
    }

    function increaseTotalReceivedEntryAsset(uint256 _amount) external onlyLatestVersion {
        totalReceivedEntryAsset += _amount;
    }

    function decreaseTotalReceivedEntryAsset(uint256 _amount) external onlyLatestVersion{
        totalReceivedEntryAsset -= _amount;
    }

    function setManagerFeeInBp(uint24 _managerFeeInBp) external onlyLatestVersion {
        managerFeeInBp = _managerFeeInBp;
    }

    function setSuccessFeeInBp(uint24 _successFeeInBp) external onlyLatestVersion {
        successFeeInBp = _successFeeInBp;
    }

    function setFeeRecepient(address _feeReceipient) external onlyLatestVersion {
        feeRecepient = _feeRecepient;
    }

    function setPoolTokenDistributionsInBP(uint24[] memory _poolTokenDistributionsInBP)  
    external 
    onlyLatestVersion {
        poolTokenDistributionsInBP = _poolTokenDistributionsInBP;
    }
}
