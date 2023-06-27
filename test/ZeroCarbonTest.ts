import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ethers } from "hardhat";
import { CarbonExchange,
     CarbonExchange__factory,
      ClaimTopicsRegistry,
      ClaimTopicsRegistry__factory,
      Identity,
      IdentityFactory,
      IdentityFactory__factory,
      IdentityRegistry,
      IdentityRegistryStorage,
      IdentityRegistryStorage__factory,
      IdentityRegistry__factory,
      Identity__factory,
      TrustedIssuersRegistry,
      TrustedIssuersRegistry__factory,
      USDT, USDT__factory,
       ZeroCarbonCredit, 
       ZeroCarbonCredit__factory,
        ZeroCarbonUnitToken,
         ZeroCarbonUnitToken__factory } from "../typechain-types";
import { expandTo18Decimals, 
    expandTo6Decimals } from "./utilities/utilities";
import { expect } from "chai";
import CarbonCreditParcel from "./utilities/parcel";

describe("Zero Carbon Platform Test Cases",()=>{

    let owner: SignerWithAddress;
    let signer: SignerWithAddress[];
    let exchange : CarbonExchange;
    let nft : ZeroCarbonCredit;
    let token: ZeroCarbonUnitToken;
    let usdt : USDT;
    let id : Identity;
    let idFactory : IdentityFactory;
    let registry : IdentityRegistry;
    let registryStorage : IdentityRegistryStorage;
    let trustedIssuerRegistry : TrustedIssuersRegistry;
    let claimTopicsRegistry : ClaimTopicsRegistry;

    let address1 = "0x0000000000000000000000000000000000000001";


    beforeEach(async()=>{
        signer = await ethers.getSigners();
        owner = signer[0];
        exchange = await new CarbonExchange__factory(owner).deploy();
        nft = await new ZeroCarbonCredit__factory(owner).deploy();
        token = await new ZeroCarbonUnitToken__factory(owner).deploy();
        usdt = await new USDT__factory(owner).deploy();
        idFactory = await new IdentityFactory__factory(owner).deploy();
        id = await new Identity__factory(owner).deploy();
        registry = await new IdentityRegistry__factory(owner).deploy();
        registryStorage = await new IdentityRegistryStorage__factory(owner).deploy();
        trustedIssuerRegistry = await new TrustedIssuersRegistry__factory(owner).deploy();
        claimTopicsRegistry = await new ClaimTopicsRegistry__factory(owner).deploy();
        await exchange.connect(owner).initialize(owner.address,200,usdt.address,nft.address,idFactory.address);
        await nft.connect(owner).initialize("Zero Carbon NFT","ZCC",owner.address,exchange.address,token.address);
        await token.connect(owner).init("ZeroCarbon Token","ZCU",0,nft.address,registry.address,owner.address);
        await idFactory.connect(owner).init(id.address,registry.address,owner.address);
        await registry.connect(owner).init(trustedIssuerRegistry.address,claimTopicsRegistry.address,registryStorage.address);
        await registryStorage.connect(owner).init();
        await registryStorage.connect(owner).bindIdentityRegistry(registry.address);
        await registry.connect(owner).addAgent(idFactory.address);
    })

    it("Testing parcel signing and listing.", async()=>{
        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer: owner
        })

        const parcel = await seller.createParcel(
            owner.address,
            1,
            20,
            200,
            23455667,
            "Sample Carbon Credit URI"
        )

        console.log("Owner address: ", owner.address);

        let addressCreated = await exchange.verifyParcel(parcel);

        console.log("Address created by parcel: ", addressCreated);

    })

    it("Setting platform fee.", async() =>{
        await exchange.connect(owner).setPlatformFeePercent(300);
        console.log("New platform fee: ", await exchange.platformFeePercent());
    })

    it("Calculate total amount to be paid.", async()=>{
        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer: owner
        })
        const parcel = await seller.createParcel(
            owner.address,
            1,
            100,
            10000000,
            1999202002,
            "Carbon credits"
        )
        console.log("Total amount calculated to be: ",await exchange.calculateTotalAmount(parcel,10));
    })

    it("Setting new admin.", async()=>{
        console.log("Current admin: ", await exchange.admin());
        await exchange.connect(owner).setAdmin(signer[1].address);
        console.log("New admin: ",await exchange.admin());
    })

    it("Enable seller stake.", async()=>{
        console.log("Current state of seller stake: ", await exchange.stakeEnabled());
        await exchange.connect(owner).enableStake(true);
        console.log("New state of seller stake: ", await exchange.stakeEnabled());
    })

    it("Buy carbon credits for the first time.", async()=>{
        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer : owner
        })
        const parcel = await seller.createParcel(
            owner.address,
            1,
            15,
            100,
            1222222,
            "Sample"
        );
        let addressReturned = await exchange.verifyParcel(parcel);
        console.log("Address owner: ", owner.address, "   Returned address: ", addressReturned);
        await exchange.connect(signer[1]).buyNFT(parcel,10,true,address1,1,{value:10000});
        console.log("Proof of sale: ", await token.balanceOf(signer[1].address));
        console.log("Max supply for carbon credit: ", await nft.maxSupplyPerCreditNFT(1));
        console.log("Total supply for carbon credit: ", await nft.currentSupplyPerCreditNFT(1));
    })

    it.only("Sending carbon credits without listing.", async()=>{

        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer : owner
        })
        const parcel = await seller.createParcel(
            owner.address,
            1,
            1000,
            100,
            1222222,
            "Sample"
        );
        let addressReturned = await exchange.verifyParcel(parcel);
        console.log("Address owner: ", owner.address, "   Returned address: ", addressReturned);
        await exchange.connect(signer[1]).buyNFT(parcel,10,true,address1,1,{value:10000});
        console.log("Proof of sale: ", await token.balanceOf(signer[1].address));
        console.log(await registry.isVerified(signer[1].address));

        await exchange.connect(signer[1]).buyNFT(parcel,10,true,address1,1,{value:10000});
        console.log("Proof of second sale: ", await token.balanceOf(signer[1].address));
        console.log(await nft.currentSupplyPerCreditNFT(1));



        // await expect(token.connect(signer[1]).transfer(signer[2].address,2)).to.be.revertedWith("Prohibited function.")
    })
})