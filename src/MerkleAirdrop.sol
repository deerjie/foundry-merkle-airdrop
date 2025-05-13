// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

using SafeERC20 for IERC20;

/*
 * @title MerkleAirdrop
 * @author cedar
 * @notice
 */

contract MerkleAirdrop is EIP712 {
    // 地址列表
    address[] public i_addresses;
    bytes32 public i_merkleRoot;
    IERC20 public i_airdropToken;
    mapping(address claimer => bool claimed) public s_hasclaimed; //用户认领状态
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }
    // error

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /**
     * 初始化默克尔树根节点和空投代币
     * @param merkleRoot merkleRoot
     * @param airdropToken airdropToken
     */
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * 认领空投
     * @param account 地址
     * @param amount 数量
     * @param merkleProof 默克尔证明
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // 阻止用户多次认领
        if (s_hasclaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // 验证签名,如果签名无效通过自定义错误恢复
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        //两次hash可以减少hash碰撞
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        console.log("MerkleProof.verify = ", MerkleProof.verify(merkleProof, i_merkleRoot, leaf));
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
    function AirTokenAddress() external view returns (IERC20) {
        return i_airdropToken;
    }

    /**
     * 校验签名，并返回布尔值
     * @param account 待验证的账户地址
     * @param digest 待验证的消息摘要
     * @param v 签名的v值组件
     * @param r 签名的r值组件
     * @param s 签名的s值组件
     */
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        private
        pure
        returns (bool)
    {
        address signer = ECDSA.recover(digest, v, r, s);
        return signer == account;
    }

    /**
     * 将已经 hash 过的结构体（structHash）和当前合约的域分隔符（domain separator）组合，
     * 生成一个最终的消息摘要（digest）。这个 digest 可以和 ECDSA 签名配合使用，用于安全地验证签名者的身份。
     * @param account 待验证的账户地址
     * @param amount 空投代币数量
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, account, amount)));
    }
}
