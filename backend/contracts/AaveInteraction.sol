// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveInteraction {
    // Create varialbes to store pool address
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    // address public immutable ADDRESS_WETH;
    address public immutable ADDRESS_MATIC_POOL;

    address owner;
    // Deposit recipient (my Address -> change to MANAGEMENTcontract??)
    address public recipient;
    // 0 as default because no middle man
    uint16 public referralCode;

    // SEE: https://docs.aave.com/developers/deployed-contracts/v3-testnet-addresses
    IWETHGateway gateway =
        IWETHGateway(0x2a58E9bbb5434FdA7FF78051a4B82cb0EF669C17);
    IERC20 aPolWMatic = IERC20(0x89a6AE840b3F8f489418933A220315eeA36d11fF);

    // CONSTRUCTOR ARG 1:
    // PoolAddressesProvider-Polygon-mumbai == 0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6
    // `payable` allows remix to deploy with value
    constructor(IPoolAddressesProvider provider) payable {
        ADDRESSES_PROVIDER = provider;
        ADDRESS_MATIC_POOL = provider.getPool();

        owner = msg.sender;
        recipient = address(this);
    }

    function deposit() external payable {
        // Needed to convert native token into ERC20 token + recieve function
        // funds are wrapped and then deposited, `this` contract is the recipient of wrapped native token.
        gateway.depositETH{value: address(this).balance}(
            ADDRESS_MATIC_POOL,
            recipient,
            referralCode
        );
    }

    function withdraw(address _recipient, uint256 _withdrawAmount) external {
        // Currently withdraws all funds
        // uint aBalance = aPolWMatic.balanceOf(address(this));
        aPolWMatic.approve(address(gateway), _withdrawAmount);

        // sends unwrapped and store matic in SC
        gateway.withdrawETH(ADDRESS_MATIC_POOL, _withdrawAmount, recipient);

        // send withdrawn funds to user
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success);
        // maybe could condense, withdrawETH(,,_recipient)
    }

    function deleteItAll() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Add fallback function
}

// Include this for non-native asset pool interaction
// import "@aave/core-v3/contracts/interfaces/IPool.sol";
// IPool public immutable POOL;
// IPool POOL = IPool(provider.getPool);
