// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LearnToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("LEARN", "LRN") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function mintToken(address recipient, uint256 amount) external {
        mint(recipient, amount);
    }

    function transferOwnershipToken(address newOwner) external {
        transferOwnership(newOwner);
        // Requires delegatecall??????? I'm pretty sure!! 4444444444
        // Currently msg.sender is InterestDistribution, but I want 0x434...
        // to be msg.sender and newOwner = InterestDistribution.
    }
}
