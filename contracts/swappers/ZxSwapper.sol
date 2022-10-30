pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

// import "@0x/contracts-zero-ex/contracts/src/features/interfaces/ITransformERC20Feature.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '../interfaces/IZxSwapper.sol';

contract ZxSwapper is IZxSwapper, Ownable {

  using SafeERC20 for IERC20;

  uint256 internal MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  address internal router = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
  address internal spotPrices = 0x7F069df72b7A39bCE9806e3AfaF579E54D8CF2b9;


  address private immutable multisendSingleton;

  constructor() {
      multisendSingleton = address(this);
  }


  function multiswap(bytes[] calldata transactions) public payable 
  returns(bytes[] memory results) {
    results = new bytes[](transactions.length);
    for (uint i; i < transactions.length; i++) {
      (bool ok, bytes memory res) = address(this).delegatecall(transactions[i]);
      require(ok == true, 'DELEGATECALL FAILED');
      results[i] = res;
    }
    return results;
  }

  // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
  function fillQuote(
      address sellToken, // The `sellTokenAddress` field from the API response.
      address buyToken, // The `buyTokenAddress` field from the API response.
      address spender, // The `allowanceTarget` field from the API response.
      uint256 amount, // Amount of wei we want to swap
      bytes calldata swapCallData // The `data` field from the API response.
  ) external
    payable {
      IERC20 sellERC = IERC20(sellToken);
      require(buyToken != address(0x0), 'Wrong tokenOut');
      require(sellERC.allowance(msg.sender, address(this)) >= amount, 'TOKEN_NOT_ALLOWED');
      sellERC.transferFrom(msg.sender, address(this), amount);
      sellERC.approve(spender, amount);
      (bool success,) = router.call(swapCallData);
      require(success, 'SWAP_CALL_FAILED');
      // payable(msg.sender).transfer(address(this).balance);
  }

  function withdraw(address token) public onlyOwner {
      require(IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this))));
  }

  function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external returns (uint256 amountOut) {
        require(_tokenIn != _tokenOut, 'INVALID_DATA');

        bytes memory payload = abi.encodeWithSignature("getRate(address, address, bool)", _tokenIn, _tokenOut, true);  
        (bool success, bytes memory result) = spotPrices.call(payload);

        // Decode data
        uint spotPrice = abi.decode(result, (uint256));
        amountOut = spotPrice * _amount;

        } 

    }
