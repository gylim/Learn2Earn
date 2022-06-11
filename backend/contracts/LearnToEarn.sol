//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract LearnToEarn {
    address public provost;
    uint256 public tuitionFee;
    uint256 public sessions;
    bool public open;
    struct Student {
        address wallet;
        uint256 lastping;
        uint256 frequency;
        uint256 pingcount;
        bool completed;
    }
    Student[] public cohort;

    event Completed(address indexed student);

    constructor(uint256 _tuitionFee, uint256 _sessions) {
        tuitionFee = _tuitionFee;
        sessions = _sessions;
        open = true;
        provost = msg.sender;
    }

    function isStudent(address _target) internal view returns(bool, uint) {
        for (uint i=0; i<cohort.length; i++) {
            if (cohort[i].wallet == _target) return (true, i);
        }
        return (false, 0);
    }
    function register(uint256 _frequency) external payable {
        require(_frequency > 0, "You will never complete the course at this rate");
        require(open == true, "The cohort is now closed, try again next time!");
        (bool tf, ) = isStudent(msg.sender);
        require(tf == false, "You are already registered");
        require(msg.value == tuitionFee, "Please pay the tuition fee");
        cohort.push(Student(msg.sender, block.timestamp, _frequency, 0, false));
    }
    function ping() external {
        (bool tf, uint idx) = isStudent(msg.sender);
        require(tf == true, "You are not a student");
        require(cohort[idx].completed == false, "You have already completed the course");
        cohort[idx].lastping = block.timestamp;
        cohort[idx].pingcount++;
        if (cohort[idx].pingcount == sessions) {
            cohort[idx].completed =true;
            emit Completed(msg.sender);
        }
    }
    function allComplete() public returns(bool, uint) {
        uint complete = 0;
        uint totalShares = 0;
        for (uint j=0; j<cohort.length; j++) {
            totalShares += cohort[j].pingcount;
            if ((block.timestamp - cohort[j].lastping) > (3*cohort[j].frequency)) {
                cohort[j].completed = true;
            }
            if (cohort[j].completed == true) complete++;
        }
        return complete == cohort.length ? (true, totalShares) : (false, 0);
    }
    function close() external {
        require(msg.sender == provost, "You are not the provost");
        require(open == true, "Registration for this cohort is already closed");
        open = false;
    }
    function payAll(uint _totalInterest) external {
        (bool tf, uint totalShares) = allComplete();
        require(tf == true, "Not all students have completed");
        require(open == false, "Cohort still open for registration");
        for (uint k=0; k<cohort.length; k++) {
            uint payout = tuitionFee + (_totalInterest * cohort[k].pingcount / totalShares);
            (bool success, ) = payable(cohort[k].wallet).call{value: payout}("");
            require(success, "Failed to send");
        }
    }
}
