// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveInteraction {
    IWETHGateway private immutable gateway;
    IERC20 private immutable aWNative;

    // Get pool from addresses provider
    address private immutable POOL;
    address payable private immutable owner;
    // The address which receives aTokens after deposit
    address private immutable aTokenHolder;
    // 0 as default, not used
    uint8 private constant referralCode = 0;

    // See arguments/argumentsAI.js for details
    constructor(
        address _gatewayAddress,
        address _tokenAddress,
        IPoolAddressesProvider _provider
    ) {
        gateway = IWETHGateway(_gatewayAddress);
        aWNative = IERC20(_tokenAddress);
        POOL = _provider.getPool();
        owner = payable(msg.sender);
        aTokenHolder = address(this);
    }

    /**
     * @dev Wraps native token to ERC20 and deposits to aave
     */
    function deposit() external payable {
        gateway.depositETH{value: address(this).balance}(
            POOL,
            aTokenHolder,
            referralCode
        );
    }

    function withdraw(address _recipient, uint256 _withdrawAmount) external {
        aWNative.approve(address(gateway), _withdrawAmount);

        // Uses aTokens, unwraps and sends to _recipient
        gateway.withdrawETH(POOL, _withdrawAmount, _recipient);
    }

    function deleteItAll() external onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    event Received(address, uint256);

    /**
     * @dev Allows this contract to receive aTokens
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Add fallback function?? 4444444444444444444444
}

// Include this for non-native asset pool interaction
// import "@aave/core-v3/contracts/interfaces/IPool.sol";
// IPool public immutable POOL;
// IPool POOL = IPool(provider.getPool);
