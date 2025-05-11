// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;
/*
 * @title MerkleAirdrop
 * @author cedar
 * @notice
 */
contract MerkleAirdrop {
    // 地址列表
    address[] public i_addresses;
    bytes32 public i_merkleRoot;
    IERC20 public i_airdropToken;
    mapping(address claimer => bool claimed) public s_hasclaimed;//用户认领状态

    // error
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    /**
     * 初始化默克尔树根节点和空投代币
     * @param merkleRoot merkleRoot
     * @param airdropToken airdropToken
     */
    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * 认领空投
     * @param account 地址
     * @param amount 数量
     * @param merkleProof 默克尔证明 
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // 阻止用户多次认领
        if(s_hasclaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        //两次hash可以减少hash碰撞
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasclaimed[account] = true;
        // 发送代币
        i_airdropToken.safeTransfer(account, amount);
    }
    /**
     * 获取默克尔树根节点
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * 查看空投Token地址
     */
    function AirTokenAddress() external view returns(IERC20) {
        return i_airdropToken;
    }


}
