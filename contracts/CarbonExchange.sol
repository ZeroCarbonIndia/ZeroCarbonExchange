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
import "contracts/interface/ICarbonCredit.sol";
import "contracts/interface/ICarbonUnits.sol";

contract CarbonExchange is Ownable, Initializable, EIP712Upgradeable, ReentrancyGuardUpgradeable {

    
    address public admin;

    address public carbonCreditNFT;

    uint96 public platformFeePercent; // in BP 10000.

    address public tether;

    bool public stakeEnabled;

    struct CarbonUnitsLeftInNFT{
        uint256 totalCarbonUnits;
        uint256 CarbonUnitsLeft;
    }

    struct PerSale{
    address seller;
    uint tokenId;
    uint noCarbonUnits;
    address currency;
    uint amount;
    uint sellerShare;
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

    mapping(address=>mapping(uint=>SellerReceipt)) public SellerAmounts;

    mapping(address=>mapping(uint=>bool)) public refundEnabled;

    mapping(address => uint) public platformCollection;

    modifier onlyAdmin() {
        require(msg.sender == admin,"You are not the admin.");
        _;
    }

    function initialize(address _admin, uint96 _platformFeePercent, address _tether, address _carbonCreditNFT) external initializer {
        require(_admin!=address(0),"Zero address.");
        require(_tether!=address(0),"Zero address");
        __EIP712_init_unchained("Zero_Carbon", "1");
        admin = _admin;
        platformFeePercent = _platformFeePercent;
        tether = _tether;
        carbonCreditNFT = _carbonCreditNFT;
        allowedCurrencies[tether] = true;
    }

    function hashParcel(Credit.CarbonCreditParcel memory parcel) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(keccak256("CarbonCreditParcel(address seller,uint256 tokenId,uint256 maxCarbonUnits,uint256 pricePerCarbonUnit,uint256 timePeriod,string tokenURI)"),
        parcel.seller,
        parcel.tokenId,
        parcel.maxCarbonUnits,
        parcel.pricePerCarbonUnit,
        parcel.timePeriod,
        keccak256(bytes(parcel.tokenURI))
        )));
    }

    function verifyParcel(Credit.CarbonCreditParcel memory parcel) public view returns(address) {
        bytes32 digest = hashParcel(parcel);
        return ECDSAUpgradeable.recover(digest, parcel.signature);
    }

    function parcelOwner(Credit.CarbonCreditParcel memory parcel) public pure returns(address){
        return parcel.seller;
    }

    function buyNFT(Credit.CarbonCreditParcel memory parcel,uint256 _noCarbonUnits,
        bool isPrimary,
        address _currency) external payable nonReentrant returns(address){
        
        address sellerAddress = verifyParcel(parcel);

        require(sellerAddress==parcel.seller,"Invalid seller.");
        if(isPrimary) {
           uint amount = calculateTotalAmount(parcel,_noCarbonUnits);

            if(_currency==address(1)){
                require(msg.value >= amount,"Invalid amount.");
                // (bool sentAmount,) = payable(parcel.seller).call{value:(parcel.pricePerFraction)*_fractions}("");
                // require(sentAmount,"Amount transfer failed.");
                saleTransaction(stakeEnabled ,parcel.seller, parcel.tokenId,_noCarbonUnits, amount, (parcel.pricePerCarbonUnit)*_noCarbonUnits, _currency);
                if(msg.value > amount){
                (bool sent,) = payable(msg.sender).call{value: msg.value - amount}("");}

            } else{
                require(allowedCurrencies[_currency],"Currency not allowed.");
                IERC20(_currency).transferFrom(msg.sender, address(this), amount);
                // saleTransaction(parcel.NFTAddress,parcel.seller,parcel.tokenId,_fractions,amount,(parcel.pricePerFraction)*_fractions, _currency);
                // IERC20(_currency).transferFrom(msg.sender, parcel.seller, (parcel.pricePerFraction)*_fractions);

            }
            ICarbonCredit(carbonCreditNFT).MintNft(msg.sender,parcel.tokenId,parcel.tokenURI,parcel.maxCarbonUnits,_noCarbonUnits,parcel.timePeriod);
            platformCollection[_currency]+= (platformFeePercent*parcel.pricePerCarbonUnit*_noCarbonUnits)/10000;
    //         
    //     }
    //     else{
    //         require(INoCapTemplate(parcel.NFTAddress).checkExist(parcel.tokenId),"NFT does not exist.");
    //         (address receiver,uint amount,uint royaltyAmount) = calculateTotalAmount(parcel,_fractions,isPrimary);
    //         if(_currency==address(1)) {
    //             require(msg.value >= amount,"Invalid amount.");
    //             (bool sentToSeller,) = payable(parcel.seller).call{value: parcel.pricePerFraction}("");
    //             platformCollection[_currency] += (platformFeePercent*parcel.pricePerFraction*_fractions)/10000;
    //             (bool royaltySent,) = payable(receiver).call{value: royaltyAmount}("");
    //             require(sentToSeller && royaltySent,"Ether transfer failed.");
    //             if(msg.value > amount){
    //             (bool sent,) = payable(msg.sender).call{value: msg.value - amount}("");}
    //         } else {
    //             require(allowedCurrencies[_currency],"Invalid currency");
    //             IERC20(_currency).transferFrom(msg.sender, parcel.seller, parcel.pricePerFraction);
    //             IERC20(_currency).transferFrom(msg.sender, address(this), (platformFeePercent*parcel.pricePerFraction*_fractions)/10000);
    //             platformCollection[_currency] += (platformFeePercent*parcel.pricePerFraction*_fractions)/10000;
    //             IERC20(_currency).transferFrom(msg.sender, receiver, royaltyAmount);
    //         }
    //             IERC20(INoCapTemplate(parcel.NFTAddress).getSTOForTokenId(parcel.tokenId)).transferFrom(parcel.seller,msg.sender,_fractions);
                
            }
    }

    function setPlatformFeePercent(uint96 _newPlatformFee) external onlyAdmin{
        platformFeePercent = _newPlatformFee;
    }

    function setAdmin(address _newAdmin) external onlyAdmin{
        admin  = _newAdmin;
    }

    function calculateTotalAmount(Credit.CarbonCreditParcel memory parcel,uint256 _noCarbonUnits) public view returns(uint256){
        uint platformAmount = (platformFeePercent*parcel.pricePerCarbonUnit*_noCarbonUnits)/10000;
        uint totalAmount;
        totalAmount = platformAmount+(parcel.pricePerCarbonUnit)*_noCarbonUnits;
        return (totalAmount);
    }

    function enableStake(bool _if) external onlyAdmin {
        stakeEnabled = _if;
    }

    function saleTransaction(bool _stakeEnabled, address _seller, uint _tokenId, uint _noCarbonUnits, uint _totalAmount, uint _sellerAmount, address _currencyAddress) internal {
        SaleReceipt storage saleReceipt = SaleReceiptForBuyer[msg.sender];
        if(stakeEnabled){
        SellerAmounts[_seller][_tokenId].currencyAddress = _currencyAddress;
        SellerAmounts[_seller][_tokenId].amount += _sellerAmount;
        }
        saleReceipt.totalTransactions++;
        PerSale storage perSale = saleReceipt.receiptPerTransaction[saleReceipt.totalTransactions];
        perSale.seller = _seller;
        perSale.tokenId = _tokenId;
        perSale.noCarbonUnits = _noCarbonUnits;
        perSale.currency = _currencyAddress;
        perSale.amount = _totalAmount;
        perSale.sellerShare = _sellerAmount;
    }

    function viewSaleReceipt(address _address, uint _transactionNo) external view returns(PerSale memory) {
        return SaleReceiptForBuyer[_address].receiptPerTransaction[_transactionNo];
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