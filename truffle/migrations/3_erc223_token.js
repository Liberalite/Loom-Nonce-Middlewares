const ERC223Token = artifacts.require('../contracts/ERC223Token.sol');

module.exports = async function (deployer) {
    await deployer.deploy(ERC223Token);
    const token = await ERC223Token.deployed();

    console.log("ERC223 Token Address:", token.address);
};