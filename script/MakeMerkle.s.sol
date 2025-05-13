// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol"; // 导入 Foundry 的 Script 库，便于脚本执行
import {stdJson} from "forge-std/StdJson.sol"; // 导入 JSON 操作库，便于解析和生成 JSON
import {console} from "forge-std/console.sol"; // 导入控制台日志库，便于调试输出
import {Merkle} from "murky/src/Merkle.sol"; // 导入 Murky 库中的 Merkle 合约，用于生成 Merkle 树
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol"; // 导入辅助脚本库，包含字符串和数组处理工具

// Merkle 证明生成脚本
// 使用方法：
// 1. 先运行 `forge script script/GenerateInput.s.sol` 生成输入文件
// 2. 再运行本脚本 `forge script script/Merkle.s.sol`
// 3. 输出文件会生成在 /script/target/output.json

/**
 * @title MakeMerkle
 * @author Ciara Nightingale
 * @author Cyfrin
 *
 * Original Work by:
 * @author kootsZhin
 * @notice https://github.com/dmfxyz/murky
 */
contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; // 允许字符串直接调用 stdJson 的方法，便于 JSON 操作

    Merkle private m = new Merkle(); // 创建 Murky Merkle 合约实例，用于生成 Merkle 树

    string private inputPath = "/script/target/input.json"; // 输入文件路径
    string private outputPath = "/script/target/output.json"; // 输出文件路径

    // 读取输入文件内容，获取绝对路径
    string private elements = vm.readFile(string.concat(vm.projectRoot(), inputPath));
    // 从 JSON 文件中读取 types 字段，获取叶子节点类型数组
    string[] private types = elements.readStringArray(".types");
    // 从 JSON 文件中读取 count 字段，获取叶子节点数量
    uint256 private count = elements.readUint(".count");

    // 创建与叶子节点数量相同大小的数组
    bytes32[] private leafs = new bytes32[](count); // 存储每个叶子节点的哈希
    string[] private inputs = new string[](count); // 存储每个叶子节点的输入数据（字符串）
    string[] private outputs = new string[](count); // 存储每个叶子节点的输出 JSON

    string private output; // 最终输出的 JSON 字符串

    /// @dev 获取输入文件中 values 字段的 JSON 路径
    function getValuesByIndex(uint256 i, uint256 j) internal pure returns (string memory) {
        // 拼接成 .values.i.j 形式的路径
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }

    /// @dev 生成输出文件的 JSON 条目
    function generateJsonEntries(string memory _inputs, string memory _proof, string memory _root, string memory _leaf)
        internal
        pure
        returns (string memory)
    {
        // 拼接 JSON 字符串，包含 inputs、proof、root、leaf 字段
        string memory result = string.concat(
            "{",
            "\"inputs\":",
            _inputs,
            ",",
            "\"proof\":",
            _proof,
            ",",
            "\"root\":\"",
            _root,
            "\",",
            "\"leaf\":\"",
            _leaf,
            "\"",
            "}"
        );

        return result;
    }

    /// @dev 读取输入文件，生成 Merkle 证明，并写入输出文件
    function run() public {
        console.log("Generating Merkle Proof for %s", inputPath); // 输出当前处理的输入文件路径

        // 遍历每个叶子节点，生成哈希和输入数据
        for (uint256 i = 0; i < count; ++i) {
            string[] memory input = new string[](types.length); // 存储每个字段的字符串表示
            bytes32[] memory data = new bytes32[](types.length); // 存储每个字段的 bytes32 表示

            for (uint256 j = 0; j < types.length; ++j) {
                if (compareStrings(types[j], "address")) {
                    // 如果类型为 address，从 JSON 读取地址
                    address value = elements.readAddress(getValuesByIndex(i, j));
                    // 地址类型先转 uint160，再转 uint256，最后转 bytes32
                    data[j] = bytes32(uint256(uint160(value)));
                    input[j] = vm.toString(value); // 字符串化存储
                } else if (compareStrings(types[j], "uint")) {
                    // 如果类型为 uint，从 JSON 读取字符串再转 uint
                    uint256 value = vm.parseUint(elements.readString(getValuesByIndex(i, j)));
                    data[j] = bytes32(value);
                    input[j] = vm.toString(value);
                }
            }
            // 生成 Merkle 树叶子节点哈希
            // 先 abi.encode 数据数组（每个元素为 bytes32），再用 ltrim64 去掉前 64 字节（offset 和 length），再 keccak256 哈希
            // bytes.concat 转为 bytes，最后再 hash 一次防止 preimage attack
            leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(data)))));
            // 将输入数组转为 JSON 字符串，存储每个叶子节点的输入
            inputs[i] = stringArrayToString(input);
        }

        // 遍历每个叶子节点，生成 proof、root、leaf、inputs 并拼接为 JSON
        for (uint256 i = 0; i < count; ++i) {
            // 获取 Merkle 证明（兄弟节点哈希数组），转为字符串
            string memory proof = bytes32ArrayToString(m.getProof(leafs, i));
            // 获取 Merkle 根哈希，转为字符串
            string memory root = vm.toString(m.getRoot(leafs));
            // 获取当前叶子节点哈希，转为字符串
            string memory leaf = vm.toString(leafs[i]);
            // 获取输入字符串
            string memory input = inputs[i];

            // 生成每个叶子节点的 JSON 输出
            outputs[i] = generateJsonEntries(input, proof, root, leaf);
        }

        // 将所有输出拼接为 JSON 数组字符串
        output = stringArrayToArrayString(outputs);
        // 写入输出文件
        vm.writeFile(string.concat(vm.projectRoot(), outputPath), output);

        // 控制台输出提示
        console.log("DONE: The output is found at %s", outputPath);
    }
}

/*
代码逐句解释：
1-5. 导入依赖库，便于脚本执行、JSON 操作、日志输出、Merkle 树生成和辅助工具。
6-13. 合约注释和作者信息。
15. 合约继承 Script 和 ScriptHelper，便于脚本运行和工具调用。
16. using stdJson for string，允许字符串直接调用 JSON 操作方法。
18. 创建 Merkle 实例。
20-21. 定义输入和输出文件路径。
23-25. 读取输入文件内容，解析 types 和 count 字段。
27-30. 创建叶子节点哈希、输入、输出数组。
32. 定义最终输出字符串。
34-38. getValuesByIndex 生成 JSON 路径。
40-56. generateJsonEntries 拼接输出 JSON。
58-131. run() 主函数：
    - 控制台输出当前处理文件。
    - 遍历每个叶子节点，读取输入、转换类型、生成哈希。
    - 遍历每个叶子节点，生成 proof、root、leaf、inputs 并拼接为 JSON。
    - 拼接所有输出为 JSON 数组，写入输出文件。
    - 控制台输出完成提示。
*/
