// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveInteraction {
    IWETHGateway immutable gateway;
    IERC20 immutable aPolWNative;

    // Get pool from addresses provider
    address public immutable POOL;

    address owner;
    // Deposit recipient
    address public recipient;
    // 0 as default because no middle man
    uint16 public referralCode;

    // See argumentsAI.js for details
    constructor(
        IPoolAddressesProvider _provider,
        address _gateway,
        address _token
    ) {
        POOL = _provider.getPool();
        gateway = IWETHGateway(_gateway);
        aPolWNative = IERC20(_token);
        owner = msg.sender;
        recipient = address(this);
    }

    // Needed to convert native token into ERC20 token + recieve function
    // funds are wrapped and then deposited, `this` contract is the recipient of wrapped native token.
    function deposit() external payable {
        gateway.depositETH{value: address(this).balance}(
            POOL,
            recipient,
            referralCode
        );
    }

    function withdraw(address _recipient, uint256 _withdrawAmount) external {
        aPolWNative.approve(address(gateway), _withdrawAmount);

        // Uses aTokens, unwraps and sends to recipient
        gateway.withdrawETH(POOL, _withdrawAmount, recipient); //change to _recipient (user) 44444444444444444444

        // send withdrawn funds to user
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success);
        // maybe could condense, withdrawETH(,,_recipient)44444444444444444444
    }

    function deleteItAll() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    event Received(address, uint256);

    // required to receive aTokens
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Add fallback function
}

// Include this for non-native asset pool interaction
// import "@aave/core-v3/contracts/interfaces/IPool.sol";
// IPool public immutable POOL;
// IPool POOL = IPool(provider.getPool);
