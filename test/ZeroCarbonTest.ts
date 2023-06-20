import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ethers } from "hardhat";
import { CarbonExchange,
     CarbonExchange__factory,
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

    beforeEach(async()=>{
        signer = await ethers.getSigners();
        owner = signer[0];
        exchange = await new CarbonExchange__factory(owner).deploy();
        nft = await new ZeroCarbonCredit__factory(owner).deploy();
        token = await new ZeroCarbonUnitToken__factory(owner).deploy();
        usdt = await new USDT__factory(owner).deploy();
        await exchange.connect(owner).initialize(owner.address,200,usdt.address,nft.address);
        await nft.connect(owner).initialize("Zero Carbon NFT","ZCC",owner.address,exchange.address);
        await token.connect(owner).init("Zero Carbon Units","ZCU",0,nft.address,owner.address);
    })

    it("Testing Parcel Signing and listing", async()=>{
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

    it("Setting platform Fee", async() =>{
        await exchange.connect(owner).setPlatformFeePercent(300);
        console.log("New palatform fee: ", await exchange.platformFeePercent());
    })

    it("Calculate total amount to be paid", async()=>{
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
        console.log("Total amount callculated to be: ",await exchange.calculateTotalAmount(parcel,10));
    })
})