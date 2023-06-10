// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/Credit.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol";

contract NoCapMarketplace is Ownable, Initializable, EIP712Upgradeable, ReentrancyGuardUpgradeable {

    
    address public admin;

    uint96 public platformFeePercent; // in BP 10000.

    address public tether;

    struct CarbonUnitsLeftInNFT{
        uint256 totalCarbonUnits;
        uint256 CarbonUnitsLeft;
    }

    struct PerSale{
    address collectionAddress;
    address seller;
    uint tokenId;
    uint fractions;
    uint amount;
    uint sellerShare;
    address currency;
    bool refundIssued;
    }

    struct SaleReceipt {
    uint totalTransactions;
    mapping(uint=>PerSale) receiptPerTransaction;
    }

    struct SellerReceipt {
        address currencyAddress;
        uint amount;
    }

    mapping(address => mapping (uint256 => bool) ) public nftMinted;

    mapping(address => mapping(uint256 => CarbonUnitsLeftInNFT)) public carbonUnitsNFT;

    mapping(address => bool) public allowedCurrencies;

    mapping(address=>SaleReceipt) public SaleReceiptForBuyer;

    mapping(address=>mapping(address=>mapping(uint=>SellerReceipt))) public SellerAmounts;

    mapping(address=>mapping(uint=>bool)) public refundEnabled;

    mapping(address => uint) public platformCollection;

    modifier onlyAdmin() {
        require(msg.sender == admin,"You are not the admin.");
        _;
    }

    function initialize(address _admin, uint96 _platformFeePercent, address _tether) external initializer {
        require(_admin!=address(0),"Zero address.");
        require(_tether!=address(0),"Zero address");
        __EIP712_init_unchained("Zero_Carbon_World", "1");
        admin = _admin;
        platformFeePercent = _platformFeePercent;
        tether = _tether;
        allowedCurrencies[tether] = true;
    }

    function hashParcel(Credit.CarbonCreditParcel memory parcel) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("CarbonCreditParcel(address seller,uint256 tokenId,uint256 maxCarbonUnits,uint256 pricePerCarbonUnit,string tokenURI)"),
        parcel.seller,
        parcel.tokenId,
        parcel.maxCarbonUnits,
        parcel.pricePerCarbonUnit,
        keccak256(bytes(parcel.tokenURI))
        )));
    }

    function verifyVoucher(Credit.CarbonCreditParcel memory parcel) public view returns(address) {
        bytes32 digest = hashParcel(parcel);
        return ECDSAUpgradeable.recover(digest, parcel.signature);
    }

    function voucherOwner(Credit.CarbonCreditParcel memory parcel) public pure returns(address){
        return parcel.seller;
    }

    // function buyNFT(Voucher.NFTVoucher memory voucher,uint256 _fractions,
    //     bool isPrimary,
    //     address _currency) external payable nonReentrant returns(address){
        
    //     address sellerAddress = verifyVoucher(voucher);

    //     require(sellerAddress==voucher.seller,"Invalid seller.");
    //     if(isPrimary) {
    //        (,uint amount,) = calculateTotalAmount(voucher,_fractions,isPrimary);
    //        require(sellerAddress==INoCapTemplate(voucher.NFTAddress).collectionAdmin(),"Only admin is allowed to list primary sale.");

    //         if(_currency==address(1)){
    //             require(msg.value >= amount,"Invalid amount.");
    //             // (bool sentAmount,) = payable(voucher.seller).call{value:(voucher.pricePerFraction)*_fractions}("");
    //             // require(sentAmount,"Amount transfer failed.");
    //             saleTransaction(voucher.NFTAddress, voucher.seller, voucher.tokenId,_fractions, amount, (voucher.pricePerFraction)*_fractions, _currency);
    //             if(msg.value > amount){
    //             (bool sent,) = payable(msg.sender).call{value: msg.value - amount}("");}

    //         } else{
    //             require(allowedCurrencies[_currency],"Currency not allowed.");
    //             IERC20(_currency).transferFrom(msg.sender, address(this), amount);
    //             saleTransaction(voucher.NFTAddress,voucher.seller,voucher.tokenId,_fractions,amount,(voucher.pricePerFraction)*_fractions, _currency);
    //             // IERC20(_currency).transferFrom(msg.sender, voucher.seller, (voucher.pricePerFraction)*_fractions);

    //         }
    //         address STO = INoCapTemplate(voucher.NFTAddress).MintNft(msg.sender, voucher.tokenId, voucher.tokenURI,voucher.seller,voucher.maxFractions, _fractions, voucher.royaltyFees);
    //         platformCollection[_currency]+= (platformFeePercent*voucher.pricePerFraction*_fractions)/10000;
    //         if(fractionsNFT[voucher.NFTAddress][voucher.tokenId].totalFractions==0){ 
    //         fractionsNFT[voucher.NFTAddress][voucher.tokenId].totalFractions= voucher.maxFractions;
    //         fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft = voucher.maxFractions - _fractions;}
    //         else{
    //         fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft -= _fractions;
    //         }
    //         return STO;
    //                     //emit event for nft creation
    //     }
    //     else{
    //         require(INoCapTemplate(voucher.NFTAddress).checkExist(voucher.tokenId),"NFT does not exist.");
    //         require(fractionsNFT[voucher.NFTAddress][voucher.tokenId].fractionsLeft==0,"Sale not allowed until all fractions are issued.");
    //         (address receiver,uint amount,uint royaltyAmount) = calculateTotalAmount(voucher,_fractions,isPrimary);
    //         if(_currency==address(1)) {
    //             require(msg.value >= amount,"Invalid amount.");
    //             (bool sentToSeller,) = payable(voucher.seller).call{value: voucher.pricePerFraction}("");
    //             platformCollection[_currency] += (platformFeePercent*voucher.pricePerFraction*_fractions)/10000;
    //             (bool royaltySent,) = payable(receiver).call{value: royaltyAmount}("");
    //             require(sentToSeller && royaltySent,"Ether transfer failed.");
    //             if(msg.value > amount){
    //             (bool sent,) = payable(msg.sender).call{value: msg.value - amount}("");}
    //         } else {
    //             require(allowedCurrencies[_currency],"Invalid currency");
    //             IERC20(_currency).transferFrom(msg.sender, voucher.seller, voucher.pricePerFraction);
    //             IERC20(_currency).transferFrom(msg.sender, address(this), (platformFeePercent*voucher.pricePerFraction*_fractions)/10000);
    //             platformCollection[_currency] += (platformFeePercent*voucher.pricePerFraction*_fractions)/10000;
    //             IERC20(_currency).transferFrom(msg.sender, receiver, royaltyAmount);
    //         }
    //             IERC20(INoCapTemplate(voucher.NFTAddress).getSTOForTokenId(voucher.tokenId)).transferFrom(voucher.seller,msg.sender,_fractions);
                
    //         }
    // }

    function setPlatformFeePercent(uint96 _newPlatformFee) external onlyAdmin{
        platformFeePercent = _newPlatformFee;
    }

    function setAdmin(address _newAdmin) external onlyAdmin{
        admin  = _newAdmin;
    }

    // function calculateTotalAmount(Voucher.NFTVoucher memory voucher,uint256 _fractions, bool _isPrimary) public view returns(address, uint256, uint256){
    //     uint platformAmount = (platformFeePercent*voucher.pricePerFraction*_fractions)/10000;
    //     uint totalAmount;
    //     address receiver;
    //     uint royaltyAmount;
    //     if(_isPrimary){
    //     totalAmount = platformAmount+(voucher.pricePerFraction)*_fractions;
    //     }
    //     else{
    //     (address receivers, uint royaltyAmounts) = INoCapTemplate(voucher.NFTAddress).royaltyInfo(voucher.tokenId, voucher.pricePerFraction);
    //     totalAmount = platformAmount+((voucher.pricePerFraction)*_fractions)+royaltyAmount;
    //     receiver = receivers;
    //     royaltyAmount = royaltyAmounts;
    //     }
    //     return (receiver,totalAmount,royaltyAmount);
    // }

    // function saleTransaction(address _collection, address _seller, uint _tokenId, uint _fractions, uint _totalAmount, uint _sellerAmount, address _currencyAddress) internal {
    //     SaleReceipt storage saleReceipt = SaleReceiptForBuyer[msg.sender];
    //     SellerAmounts[_seller][_collection][_tokenId].currencyAddress = _currencyAddress;
    //     SellerAmounts[_seller][_collection][_tokenId].amount += _sellerAmount;
    //     saleReceipt.totalTransactions++;
    //     PerSale storage perSale = saleReceipt.receiptPerTransaction[saleReceipt.totalTransactions];
    //     perSale.collectionAddress = _collection;
    //     perSale.amount = _totalAmount;
    //     perSale.seller = _seller;
    //     perSale.tokenId = _tokenId;
    //     perSale.fractions = _fractions;
    //     perSale.currency = _currencyAddress;
    //     perSale.sellerShare = _sellerAmount;
    // }

    function viewSaleReceipt(address _address, uint _transactionNo) external view returns(PerSale memory) {
        return SaleReceiptForBuyer[_address].receiptPerTransaction[_transactionNo];
    }

    function viewSellerAmounts(address _seller, address _collectionAddress, uint _tokenId) external view returns(uint, address) {
        return (SellerAmounts[_seller][_collectionAddress][_tokenId].amount,SellerAmounts[_seller][_collectionAddress][_tokenId].currencyAddress);
    }

    function withdrawPlatformAmount(address _currency) external onlyAdmin nonReentrant{
        require(allowedCurrencies[_currency],"Currency not allowed!");
        if(_currency==address(1)) {
            uint amount = address(this).balance;
            (bool sent,) = payable(msg.sender).call{value:amount}("");
            require(sent);
        }
        else{
            uint amount = IERC20(_currency).balanceOf(address(this));
            IERC20(_currency).transfer(msg.sender, amount);
        }
    }

    function updatePlatformFee(uint96 _bp) external onlyAdmin{
        platformFeePercent = _bp;
    }
}  