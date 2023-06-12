//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ICarbonUnits {
    
    function mint(address _to, uint256 _amount, uint256 _expirationPeriod) external;

}