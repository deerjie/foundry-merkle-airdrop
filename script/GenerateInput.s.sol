// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

// 该合约用于生成 Merkle 树空投的输入文件，方便后续脚本或合约读取
contract GenerateInput is Script {
    // 定义每个地址可领取的空投数量，这里为 25 个代币，单位为 1e18（通常为 18 位小数的 ERC20 代币）
    uint256 private constant AMOUNT = 25 * 1e18;
    // 定义类型数组，包含 address 和 uint 两种类型，分别对应地址和数量
    string[] types = new string[](2);
    // 记录白名单地址数量
    uint256 count;
    // 白名单地址数组，长度为 4
    string[] whitelist = new string[](4);
    // 输入文件的相对路径，生成的 JSON 文件会写入到该路径
    string private constant  INPUT_PATH = "/script/target/input.json";

    // 主执行函数，调用时会自动执行
    function run() public {
        // 初始化类型数组，第一个为 address，第二个为 uint
        types[0] = "address";
        types[1] = "uint";
        // 设置可空投的地址白名单
        whitelist[0] = "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D";
        whitelist[1] = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
        whitelist[2] = "0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd";
        whitelist[3] = "0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D";
        // 记录白名单数量
        count = whitelist.length;
        // 调用内部函数生成 JSON 字符串
        string memory input = _createJSON();
        // 将生成的 JSON 字符串写入到指定路径的文件中，路径为项目根目录 + INPUT_PATH
        vm.writeFile(string.concat(vm.projectRoot(), INPUT_PATH), input);

        // 控制台输出提示，告知用户文件已生成
        console.log("DONE: The output is found at %s", INPUT_PATH);
    }

    // 内部函数，生成符合格式的 JSON 字符串
    function _createJSON() internal view returns (string memory) {
        // 将白名单数量转为字符串
        string memory countString = vm.toString(count); // convert count to string
        // 将空投数量转为字符串
        string memory amountString = vm.toString(AMOUNT); // convert amount to string
        // 拼接 JSON 字符串的开头部分，包括类型、数量和 values 字段
        string memory json = string.concat('{ "types": ["address", "uint"], "count":', countString, ',"values": {');
        // 遍历白名单数组，为每个地址生成对应的 JSON 字段
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (i == whitelist.length - 1) {
                // 最后一个地址后不加逗号
                json = string.concat(json, '"', vm.toString(i), '"', ': { "0":', '"',whitelist[i],'"',', "1":', '"',amountString,'"', ' }');
            } else {
                // 其余地址后加逗号
                json = string.concat(json, '"', vm.toString(i), '"', ': { "0":', '"',whitelist[i],'"',', "1":', '"',amountString,'"', ' },');
            }
        }
        // 拼接 JSON 字符串的结尾部分
        json = string.concat(json, '} }');

        // 返回最终生成的 JSON 字符串
        return json;
    }
}

/*
代码逐句解释：
1. 指定文件路径和 SPDX 许可证。
2. 指定 Solidity 版本为 0.8.24。
3-5. 导入 Foundry 的 Script、StdJson、console 库，便于脚本执行、JSON 操作和日志输出。
6. 合约注释，说明用途。
7. 合约继承 Script，便于通过 Foundry 脚本运行。
8. 定义 AMOUNT 常量，表示每个地址可领取的空投数量。
9. 定义类型数组 types，包含 address 和 uint。
10. 定义 count 变量，记录白名单数量。
11. 定义 whitelist 数组，存储可空投的地址。
12. 定义输入文件路径常量 INPUT_PATH。
14-34. run() 函数为主入口：
    - 初始化 types 数组。
    - 设置白名单地址。
    - 记录白名单数量。
    - 调用 _createJSON() 生成 JSON 字符串。
    - 写入 JSON 文件到指定路径。
    - 控制台输出提示。
36-47. _createJSON() 内部函数：
    - 将 count 和 AMOUNT 转为字符串。
    - 拼接 JSON 字符串头部。
    - 遍历 whitelist，拼接每个地址和数量。
    - 拼接 JSON 结尾。
    - 返回 JSON 字符串。
*/