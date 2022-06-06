//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

library KedrLib {

    event Invested(
        address indexed user,
        uint256 entryAssetAmount,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event UnInvested(
        address indexed user,
        uint256 entryAssetAmount,
        uint16 investmentId
    );

    event Rebalanced(
        address indexed user,
        uint16 investmentId,
        uint256[] tokenBalances,
        uint24[] tokenDistribution
    );

    event Received(address sender, uint256 amount);

    struct InvestmentData {
        uint256 receivedEntryAsset;
        uint256[] tokenBalances;
        bool rebalanceEnabled;
        bool active;
        bool inputIsNativeToken;
    }

    struct InvestmentDataByUser {
        mapping(address => InvestmentData[]) map;
    }

    function getInvestment(InvestmentDataByUser storage _investmentDataByUser, address _investor, uint16 _investmentId)
    public
    returns (InvestmentData memory)
    {
        return _investmentData.map[_investor][_investmentId];
    }

    function getInvestments(InvestmentDataByUser storage _investmentData, address _investor)
    public
    returns (InvestmentData[] memory)
    {
        return _investmentData.map[_investor];
    }
}