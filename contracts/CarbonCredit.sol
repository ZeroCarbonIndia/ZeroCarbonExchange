//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/interface/ICarbonUnits.sol";

contract ZeroCarbonCredit is ERC721URIStorageUpgradeable, EIP712Upgradeable, Ownable {

address public admin;
address public exchange;
address public carbonUnitsToken;
uint256 private totalSupply;
uint256 private _totalCarbonUnits;

struct CarbonUnitsHistory {
        uint256 txId;
        uint256 amount;
        uint256 owner;
        uint256 expirationPeriod;
    }


modifier onlyAdmin{
    require(msg.sender==admin,"You are not the admin.");
    _;
}

function initialize(string memory _name, string memory _symbol, address _admin,address _exchange) external initializer {
    require(_admin != address(0), "ZAA"); //Zero Address for Admin
    require(_exchange != address(0), "ZAM");//Zero Address for Marketplace
    __ERC721_init_unchained(_name, _symbol);
    __EIP712_init_unchained(_name, "1");
    admin = _admin;
    exchange = _exchange;
    }

function MintNft(address _to, uint _tokenId, string memory _tokenURI,uint256 _maxCarbonUnits, uint256 _noCarbonUnits, uint256 _expirationPeriod) external{
    require(msg.sender== exchange, "Call only allowed from Carbon Exchange");
    if(_exists(_tokenId)){
    ICarbonUnits(carbonUnitsToken).mint(_to, _noCarbonUnits, _expirationPeriod);
    }
    else {
    _safeMint(carbonUnitsToken, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
    totalSupply++;
    ICarbonUnits(carbonUnitsToken).mint(_to, _noCarbonUnits, _expirationPeriod);
        
     }
}

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

function getAdmin() external view returns(address){
    return admin;
}    

}
