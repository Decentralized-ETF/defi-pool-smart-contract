//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;

library KedrLib {

    event Invested(
        address indexed user,
        uint256 receivedEntryAssetAmount,
        uint256[] tokenBalanceAmounts
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
        uint256 receivedEntryAssetAmount;
        uint256[] tokenBalanceAmounts;
        bool active;
    }

    struct InvestmentDataByUser {
        mapping(address => InvestmentData[]) map;
    }

    function updateInvestment(InvestmentDataByUser storage _investmentDataByUser,
        address _investor,
        uint16 _investmentId,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts,
        bool _active
    ) public {
        _investmentDataByUser.map[_investor][_investmentId].active = _active;
        _investmentDataByUser.map[_investor][_investmentId].tokenBalanceAmounts = _tokenBalanceAmounts;
        _investmentDataByUser.map[_investor][_investmentId].receivedEntryAssetAmount = _receivedEntryAssetAmount;
    }

    function getInvestment(InvestmentDataByUser storage _investmentDataByUser, address _investor, uint16 _investmentId)
    public
    view
    returns (InvestmentData memory)
    {
        return _investmentDataByUser.map[_investor][_investmentId];
    }

    function getInvestments(InvestmentDataByUser storage _investmentDataByUser, address _investor)
    public
    view
    returns (InvestmentData[] memory)
    {
        return _investmentDataByUser.map[_investor];
    }

    function startInvestment(InvestmentDataByUser storage _investmentDataByUser,
        address _investor,
        uint256 _receivedEntryAssetAmount,
        uint256[] memory _tokenBalanceAmounts) public {
        _investmentDataByUser.map[_investor].push(InvestmentData({
        receivedEntryAssetAmount : _receivedEntryAssetAmount,
        tokenBalanceAmounts : _tokenBalanceAmounts,
        active : true
        }));
    }

}