// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BagelToken
 * @author cedar
 * @notice 空头代币合约
 */
contract BagelToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, address initialOwner)
        ERC20(name, symbol)
        Ownable(initialOwner)
    {}
    /**
     * @notice Mint tokens to the specified account
     * @param account The address to mint tokens to
     * @param value The amount of tokens to mint
     */
    function mint(address account, uint256 value) public {
        _mint(account, value);
    }
}
