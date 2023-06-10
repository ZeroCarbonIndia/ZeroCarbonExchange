library Credit {

    struct CarbonCreditParcel{
        address seller;
        uint256 tokenId;
        uint256 maxCarbonUnits;
        uint256 pricePerCarbonUnit;
        uint256 timerPeriod;
        string tokenURI;
        bytes signature;
    }
}