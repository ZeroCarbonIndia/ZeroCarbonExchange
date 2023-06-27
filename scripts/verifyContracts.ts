const Hre = require("hardhat");

async function main() {


    await Hre.run("verify:verify", {
      //Deployed contract Factory address
      address: "0x1f9Abd7c4c8B21c3c1BA09a1aD8e2Fb312Cbc55B",
      //Path of your main contract.
      contract: "contracts/CarbonExchange.sol:CarbonExchange",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Factory address
      address: "0x2f83F3660D0D725b210A73710f7c3af316c6A230",
      //Path of your main contract.
      contract: "contracts/CarbonCredit.sol:ZeroCarbonCredit",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0x0F191bBc1854Bab6e52e3AfD49c64FE8b7a03410",
      //Path of your main contract.
      contract: "contracts/CarbonUnits.sol:ZeroCarbonUnitToken",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0x419a129851F7B3659DCd7667F3AE931f0261AD4F",
      //Path of your main contract.
      contract: "contracts/Proxy/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy",
    });

    await Hre.run("verify:verify", {
      //Deployed contract Marketplace address
      address: "0x3832F99f45979cEDF67603CB4235253E4664C3C3",
      //Path of your main contract.
      contract: "contracts/Proxy/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy",
    });

    await Hre.run("verify:verify",{
      //Deployed contract MarketPlace proxy
      address: "0x6b27069b128b5Cb3961721767c1B0dC661B776F7",
      //Path of your main contract.
      contract: "contracts/Proxy/OwnedUpgradeabilityProxy.sol:OwnedUpgradeabilityProxy"
    });


}
main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});