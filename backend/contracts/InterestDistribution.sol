// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InterestDistribution {
    //0x8D211AfD3eE76Dbac6B545AFDc51CdaC92997D37 address of smart contract
    IERC20 aPolWMatic = IERC20(0x89a6AE840b3F8f489418933A220315eeA36d11fF);

    // Check the AdminContract balance
    function getBalance(address tokenHolder) external view returns (uint256) {
        return aPolWMatic.balanceOf(tokenHolder);
    }

    address[] public accounts;

    // record initial user input amount and time for interest calculations
    mapping(address => uint256) initialDeposit;
    uint256 totalDeposits;
    mapping(address => uint256) blockNumberOnJoin;

    mapping(address => uint256) earnedInterest;

    // having both allows us to see if we have over allocated rewards
    uint256 totalInterestAllocated;
    uint256 totalInterestEarned;

    // have a time dedicated for the start of each reward window;
    uint256 todayUTC0;

    // storage for total aTokens at the start of each time period
    mapping(uint256 => uint256) aTokensTotal;

    uint256 rewardPeriod;

    // USE chainLink keeper function to update on time
    // If one day has passed or if a new user joins:
    function keeper() external {
        if (
            // block.timestamp >= (todayUTC0 + 1 days) ||
            // tranferFromNewUser() == true
        ) {
            // currently invalid || syntax
            rewardPeriod++;
            // distributeFunds();
        }
    }

    function distributeFunds() internal {
        for (each account in the array) {
            uint percentShare = initialDeposit[account] / totalDeposits;
            aTokensToAllocate = aTokensEnd - aTokensStart;
            earnedInterest[account] += aTokensToAllocate * percentShare;
            //the first address will be the contract address, so it receives some interest
        }

    }
    |-----|-----|-----|--\---|-----|
}

// Keeper or no keeper??

// ping keeper?

// Listen for front end ping

// Read the data from
// deploy with a start date
// on start date take the total number of users,
// on register users are added to the total number of students
// as user completes work, they get to submit ping
// when their ping count is at 5, then they have completed the course
// when the start date + 5 days is reached, keepers release funds to users
// 

interface IAaveInteraction {
    function deposit() external payable;
}

contract InterestDistribution2 {

// Testing
// uint public interestPrevPeriod;
// uint public totalAwarded;


// Could neaten these up by using a struct, nested mapping ,iterable mapping??? 4444444444444444444444
address[] public students;
mapping(address => uint256) initialDeposit;
mapping(address => uint256) interestEarned;
uint depositTotal;
mapping(address => uint256) pingExpiresAt; // 2^32 -1 equals to 4294967295 = 07/02/2106

uint256 todayUTC0;
IERC20 aPolWMatic = IERC20(0x89a6AE840b3F8f489418933A220315eeA36d11fF);

constructor (uint256 _todayUTC0) payable {
    todayUTC0 = _todayUTC0;
    // for contract to have some gas(maybe not needed)
    // deposit{value: msg.value}();
}

uint prevATokenBal;
uint curATokenBal;
function register() external payable {
    // Issue interest from previous remuneration period
    calcInterestPrevPeriod();

    // Add new student
    students.push(msg.sender);
    initialDeposit[msg.sender] = msg.value;
    depositTotal += msg.value;

    // ping active for rest of day + 1 days
    ping();

    //Deposit user funds into Aave
    IAaveInteraction(IAIAddress).deposit{value: msg.value}();

    // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
    prevATokenBal = aPolWMatic.balanceOf(address(this));
}

function calcInterestPrevPeriod() internal {
    curATokenBal = aPolWMatic.balanceOf(address(this));
    interestPrevPeriod = curATokenBal - prevATokenBal;

    uint unclaimedInterest;
    uint unclaimedDepositTotal;

    // If inactive, accumulate funds to re-distribute 
    for (uint i = 0; i < students.length; i++) {
        address student = students[i];
        uint deposit = initialDeposit[student];
        uint studentShare = deposit / depositTotal;

        if (pingExpiresAt[student] < block.timestamp) {
            unclaimedInterest += interestPrevPeriod * studentShare;
            unclaimedDepositTotal += deposit;
        }
    }

    // If active, student gets default and unclaimed share
    for (uint i = 0; i < students.length; i++) {
        address student = students[i];
        uint deposit = initialDeposit[student];

        uint studentShare = deposit / depositTotal;
        uint studentShareUnclaimed = deposit / (depositTotal - unclaimedDepositTotal);

        if (pingExpiresAt[student] >= block.timestamp) {
            // default share
            interestEarned[student] += interestPrevPeriod * studentShare;
            // share of unclaimed
            interestEarned[student] += unclaimedInterest * studentShareUnclaimed;
            
            // Testing
            // totalAwarded += interestPrevPeriod * studentShare;
        }
    }
}

function endOfDay() external {

}

function ping() internal {
    // |------|----p--|------|
    //     tUTC0      +1     +2
    // ping lasts until the end of the day and the following (allows for spam ping each day)

    // will this be the contract? will I need delegate call?
    // who is the msg.sender of internal call function
    pingExpiresAt[msg.sender] = todayUTC0 + 2 days;;
}


// KEEPER check for 24hr
uint256 interval = 1 days; // maybe uint32  
// ^^ Is this valid syntax?? uint
function checkUpkeep( bytes calldata ) external view override 
    returns ( bool upkeepNeeded, bytes memory ) {
    upkeepNeeded = (block.timestamp - todayUTC0) > interval;
}

function performUpkeep( bytes calldata ) external override {
    // Re-validation check
    if ((block.timestamp - todayUTC0) > interval) {
        // Could automate todayUTC0 with % ?? where upkeep handles all time parameters 4444444444444444
        todayUTC0 += 1 days;
        calcInterestPrevPeriod();
        // the previous balance is updated to the Current balance as no additional funds are added (as in recipient) 
        prevATokenBal = curATokenBal;
    }
}

function payout() external {
    // Once the period has finished check the interest mapping, distribute to users
    // once day 10 is reached, show button, allow users to withdraw
    require(complete[student] == true)
    calcInterestPrevPeriod();

    withdrawAmount = interestEarned[msg.sender] + initialDeposit[msg.sender];
    depositTotal[msg.sender] -= initialDeposit[msg.sender];
    interestEarned[msg.sender] = 0;
    initialDeposit[msg.sender] = 0;
    // Is there a safer way to do this?? withdraw doesn't seem to return an uint/ or any value...
    IAaveInteraction(IAIAddress).withdraw{value: withdrawAmount}();
    (bool success, ) = msg.sender.call{address(this).balance}("");
    requrie(success);

    // track the first ping from register() and calculate the completion date to allow payout to be callable.
    // first UTC0 + number of study days
    require(recordedStartDay[msg.sender] + sessions days, "You can only receive a payout once all study sessions is complete");

}

function register() external payable {
    // Issue interest from previous remuneration period
    calcInterestPrevPeriod();

    // Add new student
    students.push(msg.sender);
    initialDeposit[msg.sender] = msg.value;
    depositTotal += msg.value;

    // ping active for rest of day + 1 days
    ping();

    //Deposit user funds into Aave
    IAaveInteraction(IAIAddress).deposit{value: msg.value}();

    // Update prevATokenBal for when register() calls calcInterestPrevPeriod() next time
    prevATokenBal = aPolWMatic.balanceOf(address(this));
}

// can I have a latestDayTime?
// currentDayStartTime = 
// if block.timestamp >= currentDay + 86400 then update the time
// LAUNCH_DATE = Some Unix timestamp at midnight ( use calculator )
// todayUTC0, launch this with constructor

    function distributeFunds() internal {
        for (each account in the array) {
            uint percentShare = initialDeposit[account] / totalDeposits;
            aTokensToAllocate = aTokensEnd - aTokensStart;
            earnedInterest[account] += aTokensToAllocate * percentShare;
            //the first address will be the contract address, so it receives some interest
        }

    }
    uint payout = cohort[k].tuitionFee +
                _totalInterest *
                (cohort[k].tuitionFee / totalDep) *
                (cohort[k].pingcount / sessions);
}


}
// on deployment of contract send some funds into aave (surplus funds will be added to this??)
// user registers, their funds go into aave
// store their initial deposit in a mapping
// have an array of Struct which contains student address, this will allow awards to be given to users (maybe just array)
// keeper will update user interest earnings based on their proportional deposited funds
// keeper will check the ping status of each user in the array
// if the ping status is true award funds
// ping at any stage in a 24hr period to earn interest for the next 24hr period (use the Official start plus x days)


// aave protocal aToken balance can only increase, so each keeper update will distribute funds (but is this accurate?? I can test this once set up. if not accurate withdraw then redeposit)
// users can withdraw funds at any time, any forefitted earning go to procol
// the next 24hr period they click ping and they become elidgable for reward