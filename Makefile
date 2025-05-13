
install :; forge install OpenZeppelin/openzeppelin-contracts && forge install dmfxyz/murky

generateMerkleInput :; forge script script/GenerateInput.s.sol:GenerateInput
makeMerkleProof :; forge script script/MakeMerkle.s.sol:MakeMerkle