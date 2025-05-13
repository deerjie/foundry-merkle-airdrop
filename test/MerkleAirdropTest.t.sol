// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "@devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

/**
 * @title MerkleAirdrop.t
 * @author cedar
 * @notice 测试空投合约
 */
contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    DeployMerkleAirdrop deploy;
    MerkleAirdrop public airdrop;
    BagelToken public token;
    bytes32 constant merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address private user;
    uint256 private privateKey;
    uint256 AMOUNT_TO_CLAIM = 25 * 1e18; // 每个地址可领取的空投数量
    uint256 AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4; // 空投代币的总供应量
    address public gasPayer; // gas支付者地址




    function setUp() public {
        if (isZkSyncChain()) {
            token = new BagelToken("BagelToken", "Bagel");
            airdrop = new MerkleAirdrop(merkleRoot, token);
            //铸造空投代币
            token.mint(address(airdrop), AMOUNT_TO_SEND);
        } else {
            deploy = new DeployMerkleAirdrop();
            (airdrop, token) = deploy.run();
        }
        (user, privateKey) = makeAddrAndKey("user");
        // gas支付者地址
        gasPayer = makeAddr("gasPayer");
    }
    /**
     * 获取作弊代码生成的用户地址
     */

    function getUserAddress() public view {
        //将生成的地址加入到默克尔树中
        console.log("user address:", user);
    }

    /**
     * 用户签名授权，第三方帮忙发起交易，为的是第三方代付 gas”这种常见的空投/授权场景。
     */
    function testUsersCanClim() public {
        uint256 startingBalance = token.balanceOf(user);
        // Get message hash for signature verification
        bytes32 digist = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        //对摘要进行签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digist);
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, getProof(), v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("Ending Banlance", endingBalance);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }

    // Merkle proof 示例，作为函数返回 memory 数组
    function getProof() internal pure returns (bytes32[] memory) {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
        proof[1] = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
        return proof;
    }
}
