//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZeroCarbonCredit is ERC721URIStorageUpgradeable, EIP712Upgradeable, Ownable {

address public _admin;
address public _exchange;
uint256 private totalSupply;
uint256 private _totalCarbonUnits;

struct CarbonUnitsHistory {
        uint256 txId;
        uint256 amount;
        uint256 owner;
        uint256 expirationPeriod;
    }


modifier onlyAdmin{
    require(msg.sender==_admin,"You are not the admin.");
    _;
}

function initialize(string memory _name, string memory _symbol, address _admin, uint96 _royaltyAmount,address _exchange, address _securityTokenFactory) external initializer {
    require(_admin != address(0), "ZAA"); //Zero Address for Admin
    require(_exchange != address(0), "ZAM");//Zero Address for Marketplace
    __ERC721_init_unchained(_name, _symbol);
    __EIP712_init_unchained(_name, "1");
    _admin = _admin;
    _exchange = _exchange;
    }

//function MintNft(address _to, uint _tokenId, string memory _tokenURI, address _royaltyKeeper,uint256 _maxFractions, uint256 _fractions, uint96 _royaltyFees) external returns(address){
//      require(msg.sender== marketPlace, "Call only allowed from marketplace");
//      if(STOForTokenId[_tokenId]==address(0)){
//      address STO = ISecurityTokenFactory(securityTokenFactory).deployTokenForNFT("NoCap NFT STO", "NOCAPSTO", 0, _tokenId,_maxFractions);
//      _safeMint(STO, _tokenId);
//      _setTokenURI(_tokenId, _tokenURI);
//      totalSupply++;
//      if(_royaltyKeeper != address(0)){
//      _setTokenRoyalty(_tokenId, _royaltyKeeper, _royaltyFees);}
//      STOForTokenId[_tokenId] = STO;
//      IFractionToken(STO).mint(_to, _fractions);
//      }
//      else {
//         IFractionToken(STOForTokenId[_tokenId]).mint(_to, _fractions);
//      }
//      return STOForTokenId[_tokenId];
// }

function updateTokenURI(uint tokenId, string memory _tokenURI) external onlyAdmin{
    _setTokenURI(tokenId, _tokenURI);
}

function _totalSupply() external view virtual returns(uint256) {
    return totalSupply;
}

function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

 function _msgData()
        internal
        pure
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

 function _msgSender()
        internal
        view
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

 function checkExist(uint _tokenId) external view returns(bool) {
    return _exists(_tokenId);
 }   

function admin() external view returns(address){
    return _admin;
}    

}
