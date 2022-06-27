// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInterestDistribution {
    function getWithdrawAmount(address stu) external view returns (uint);

    // function getStudentStatus() external view returns (bool);
}

contract AaveInteraction {
    IWETHGateway private immutable gateway;
    IERC20 private immutable aWNative;

    bool public connected = false;
    IInterestDistribution private distribution;
    address private interestDistribution;

    function setAddress(address _Distribution) external onlyOwner {
        // require(!connected, "The contract has already been connected");
        connected = true;
        distribution = IInterestDistribution(_Distribution);
        interestDistribution = _Distribution;
    }

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
        // Upgrade to onlyStudent Modifier 44444444444444444
        gateway.depositETH{value: address(this).balance}(
            POOL,
            aTokenHolder,
            referralCode
        );
    }

    function withdraw(address _recipient) external {
        // Upgrade to onlyStudent Modifier 444444444444444444
        // Read mappings from InterestDistribution
        uint withdrawAmount = distribution.getWithdrawAmount(_recipient);

        aWNative.approve(address(gateway), withdrawAmount);

        // Uses aTokens, unwraps and sends to _recipient
        gateway.withdrawETH(POOL, withdrawAmount, _recipient);
    }

    function deleteItAll() external onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    // modifier onlyStudents() {
    //     // (bool success, ) = interestDistribution.delegatecall(
    //     //     abi.encodeWithSelector(distribution.getStudentStatus.selector)
    //     // );
    //     // require(success);
    //     // require(distribution.getWithdrawAmount(student), "Only students can deposit funds");
    //     // (Current issue Delegatecall, msg.sender will not be passed on correctly)
    //     require(
    //         distribution.getStudentStatus(msg.sender),
    //         "You are not a registered student"
    //     );
    //     _;
    // }

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
