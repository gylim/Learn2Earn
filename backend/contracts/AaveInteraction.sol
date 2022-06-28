// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/misc/interfaces/IWETHGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILearnToEarn {
    function getWithdrawAmount(address stu) external view returns (uint);

    // function getStudentStatus() external view returns (bool); 444
}

contract AaveInteraction {
    IWETHGateway private immutable gateway;
    IERC20 private immutable aWNative;
    ILearnToEarn private learnToEarn;

    bool public connected = false;

    // Get pool from addresses provider
    address private immutable POOL;
    address payable private immutable owner;
    // The address which receives aTokens after deposit
    address private immutable aTokenHolder;
    // 0 as default, not used
    uint8 private constant referralCode = 0;

    modifier onlyOwner() {
        require(owner == msg.sender, "msg.sender must be the owner");
        _;
    }

    event Received(address, uint256);

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

    /** @dev Allows this contract to receive aTokens */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Add fallback function?? 444

    /** @dev Opens communication path to InterestDistribution */
    function setAddress(address _LearnToEarn) external onlyOwner {
        // require(!connected, "The contract has already been connected"); 222
        connected = true;
        learnToEarn = ILearnToEarn(_LearnToEarn);
    }

    /** @dev Wraps native token to ERC20 and deposits to aave */
    function deposit() external payable {
        // Upgrade to onlyStudent Modifier 444
        gateway.depositETH{value: address(this).balance}(
            POOL,
            aTokenHolder,
            referralCode
        );
    }

    function withdraw(address _recipient) external {
        // Upgrade to onlyStudent Modifier 444
        // Reads mappings from InterestDistribution
        uint withdrawAmount = learnToEarn.getWithdrawAmount(_recipient);

        aWNative.approve(address(gateway), withdrawAmount);

        // Uses aTokens, unwraps and sends to _recipient
        gateway.withdrawETH(POOL, withdrawAmount, _recipient);
    }

    // 444 DelegateCall

    // modifier onlyStudents() {
    //     // (bool success, ) = learnToEarn.delegatecall(
    //     //     abi.encodeWithSelector(learnToEarn.getStudentStatus.selector)
    //     // );
    //     // require(success);
    //     // require(learnToEarn.getWithdrawAmount(student), "Only students can deposit funds");
    //     // (Current issue Delegatecall, msg.sender will not be passed on correctly)
    //     require(
    //         learnToEarn.getStudentStatus(msg.sender),
    //         "You are not a registered student"
    //     );
    //     _;
    // }
}

// Include this for non-native asset pool interaction
// import "@aave/core-v3/contracts/interfaces/IPool.sol";
// IPool public immutable POOL;
// IPool POOL = IPool(provider.getPool);
