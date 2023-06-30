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

      expect(await exchange.verifyParcel(parcel)).to.be.eq(owner.address)

    })

    it("Setting platform fee.", async() =>{
        await exchange.connect(owner).setPlatformFeePercent(300);
        expect(await exchange.platformFeePercent()).to.be.eq(300);
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

        expect(await exchange.calculateTotalAmount(parcel,10)).to.be.eq(102000000)
    })

    it("Setting new admin.", async()=>{
        console.log("Current admin: ", await exchange.admin());
        await exchange.connect(owner).setAdmin(signer[1].address);
        expect(await exchange.admin()).to.be.eq(signer[1].address);
    })

    it("Enable seller stake.", async()=>{
        expect(await exchange.stakeEnabled()).to.be.eq(false);
        await exchange.connect(owner).enableStake(true);
        expect(await exchange.stakeEnabled()).to.be.eq(true);
    })

    it("Buy carbon credits for the first time from eth", async()=>{
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
        await exchange.connect(signer[1]).buyNFT(parcel,10,true,address1,1,{value:10000});
        expect(await token.balanceOf(signer[1].address)).to.be.eq(10);
        expect(await nft.maxSupplyPerCreditNFT(1)).to.be.eq(15);
        expect( await nft.currentSupplyPerCreditNFT(1)).to.be.eq(10);
    })

    it("Buy carbon credits for the first time from USDT", async()=>{
        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer : owner
        })
        const parcel = await seller.createParcel(
            owner.address,
            1,
            15,
            expandTo6Decimals(10),
            1222222,
            "Sample"
        );
        await usdt.connect(owner).mint(signer[1].address, expandTo6Decimals(1000));
        await usdt.connect(signer[1]).approve(exchange.address,expandTo6Decimals(102))
        await exchange.connect(signer[1]).buyNFT(parcel,10,true,usdt.address,1);
        expect(await token.balanceOf(signer[1].address)).to.be.eq(10);
        expect(await nft.maxSupplyPerCreditNFT(1)).to.be.eq(15);
        expect( await nft.currentSupplyPerCreditNFT(1)).to.be.eq(10);
    })


    it.only("Buy carbon credits for the second time from eth", async()=>{
        const seller = await new CarbonCreditParcel({
            _contract: exchange,
            _signer : owner
        })
        const parcel = await seller.createParcel(
            owner.address,
            1,
            15,
            100,
            1688309246,
            "Sample"
        );
        await exchange.connect(signer[1]).buyNFT(parcel,10,true,address1,1,{value:10000});
        expect(await token.balanceOf(signer[1].address)).to.be.eq(10);
        expect(await nft.maxSupplyPerCreditNFT(1)).to.be.eq(15);
        expect( await nft.currentSupplyPerCreditNFT(1)).to.be.eq(10);
        const seller2 = await new CarbonCreditParcel({
            _contract: exchange,
            _signer : signer[1]
        })

        const parcel2 = await seller2.createParcel(
            signer[1].address,
            1,
            5,
            50,
            1688309246,
            "Test_URI"
        )
        // console.log(await token.connect(owner).transferFrom());
        // console.log(await exchange.carbonCreditNFT());
        // await idFactory.connect(signer[2]).createAndRegisterIdentity(signer[2].address,1);
        await token.connect(signer[1]).approve(exchange.address,1);
        await exchange.connect(signer[2]).buyNFT(parcel2, 3,false,address1,1,{value: 155});
        expect(await token.balanceOf(signer[2].address)).to.be.eq(3);
        expect(await nft.maxSupplyPerCreditNFT(1)).to.be.eq(15);
        expect( await nft.currentSupplyPerCreditNFT(1)).to.be.eq(10);
    })


    it("Sending carbon credits without listing.", async()=>{

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