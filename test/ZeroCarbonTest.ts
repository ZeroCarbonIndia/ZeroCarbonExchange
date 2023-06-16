import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ethers } from "hardhat";
import { CarbonExchange, CarbonExchange__factory, USDT, USDT__factory, ZeroCarbonCredit, ZeroCarbonCredit__factory, ZeroCarbonUnitToken, ZeroCarbonUnitToken__factory } from "../typechain-types";
import { expandTo18Decimals, expandTo6Decimals } from "./utilities/utilities";
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

    console.log("Collection Exist: ",await factory.checkNoCapNFT(NFTAddress));
        console.log("Amount I should pay: ", await marketplace.calculateTotalAmount(voucher,1,true));
        await marketplace.connect(signers[1]).buyNFT(voucher,4,true,"0x0000000000000000000000000000000000000001",{value: 3000000000});
        let nftCreated = await new NoCapTemplateERC721__factory(owner).attach(NFTAddress);
        console.log("Success: ", await nftCreated.balanceOf("0x3b5295ffD4615174abA74292Be3137E33eFeedF8"));
        console.log(await nftCreated.ownerOf(1));
        console.log("STO for token ID: ", await nftCreated.STOForTokenId(1));
        let fractionSTO = await new FractionToken__factory(owner).attach("0x3b5295ffD4615174abA74292Be3137E33eFeedF8");
        console.log("Fractions Received: ", await fractionSTO.balanceOf(signers[1].address));

        // await marketplace.connect(signers[2]).buyNFT(voucher2,1,true,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(204)});
        console.log("Fractions for second Buyer : ", await fractionSTO.balanceOf(signers[2].address));

        // Checking SEcondary sale on the marketplace :

        const sellerSecondary = await new NoCapVoucher({
            _contract : marketplace,
            _signer : signers[1],
        });

        // const voucherSecondary = await sellerSecondary.createVoucher(
        //     signers[1].address,
        //     NFTAddress,
        //     1,
        //     2,
        //     expandTo18Decimals(100),
        //     false,
        //     owner.address,
        //     200,
        //     "Sample URI"
        // );

        // let addressChecked = await marketplace.connect(owner).verifyVoucher(voucherSecondary);
        // console.log("Original address: ", signers[1].address, "Created address :", addressChecked);

        // await fractionSTO.connect(signers[1]).approve(marketplace.address,2);

        // await expect(marketplace.connect(signers[2]).buyNFT(voucherSecondary,1,false,"0x0000000000000000000000000000000000000001",{value: expandTo18Decimals(104)})).to.be.revertedWith("Sale not allowed until all fractions are issued.");

        // console.log("New fraction balance: ", await fractionSTO.balanceOf(signers[2].address));

        console.log("Buyer receipt", await marketplace.viewSaleReceipt(signers[1].address,1));
        console.log("Balance before burn delivery: ",await fractionSTO.balanceOf(signers[1].address));

        await nftCreated.connect(owner).burnOnDelivery(1,signers[1].address);
        console.log("Balance after burn delivery: ",await expect(fractionSTO.balanceOf(signers[1].address)).to.be.reverted);
    })

    it.only("Deploy NFT Collection", async()=>{
        await identityFactory.connect(signers[3]).createAndRegisterIdentity(1);
        await factory.connect(signers[3]).deployNFTCollection("MyNFTCollection","MNFT",signers[3].address,300);
        let instanceAddress = await factory.getCollectionAddress(signers[3].address,1);
        let instance = await new NoCapTemplateERC721__factory(signers[3]).attach(instanceAddress);
        console.log("NFT Details: ", await instance.name());
    })

    it.only("Deploy NFT Collection(Negative)", async()=>{
        await identityFactory.connect(signers[3]).createAndRegisterIdentity(1);
        await expect(factory.connect(signers[3]).deployNFTCollection("MyNFTCollection","MNFT","0x0000000000000000000000000000000000000000",300))
        .to.be.revertedWith("Zero address.");
    })

    it("Update Template Address", async()=>{
        await factory.connect(owner).updateTemplateAddress(signers[4].address);
        console.log("Success.");
    })    it(": Update Admin Address", async()=>{
        await factory.connect(owner).updateAdmin(signers[1].address);
        console.log("Success");
    })

    it(": Update Admin Address(Negative)", async()=>{
        await expect(factory.connect(signers[1]).updateAdmin(owner.address)).to.be.revertedWith("You are not the admin.");
        console.log("Only admin modifier covered.");
    })

    it(": HashVoucher Verfied", async()=>{
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        console.log("Collection Address: ", NFTAddress);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        const voucher = await seller.createVoucher(
            owner.address,
            NFTAddress,
            1,
            4,
            expandTo18Decimals(100),
            true,
            owner.address,
            200,
            "Latest Collection");

        let addressCreated = await marketplace.verifyVoucher(voucher);
        expect(addressCreated).to.be.eq(owner.address);
        console.log("Address match expect passed. Owner Address: ", owner.address,"Address Created: ", addressCreated);
    })

    it(": Buy NFT(Primary Sale)",async() => {
        let NFTAddress = await factory.getCollectionAddress(owner.address,2);
        console.log("Collection Address: ", NFTAddress);
        const seller = await new NoCapVoucher({
            _contract : marketplace,
            _signer : owner,
        })

        await marketplace.connect(signers[2]).buyNFT(voucher,2,true,"0x0000000000000000000000000000000000000001",{value:expandTo18Decimals(204)});
        let nftContract = await new NoCapTemplateERC721__factory(owner).attach(NFTAddress);
        let stoAddress = await nftContract.STOForTokenId(1);
        console.log("TokenID STO: ", stoAddress);
        let STO = await new TokenST__factory(owner).attach(stoAddress);
        console.log("Proof of ownership: ", await STO.balanceOf(signers[2].address));
    })




})