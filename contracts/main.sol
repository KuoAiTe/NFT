// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OurNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // 是否准許合約開賣NFT
    bool public _isSale = true;
    // 是否准許客戶私下轉讓NFT
    bool public _isTransactional = false;
    // 盲盒顯示
    bool public _revealed = false;

    // Constants
    // 合約名字

    string public constant contractName = "NFT";
    string public constant contractSymbol = "NFTSYN";
    // NFT最大總數量
    uint256 public constant MAX_SUPPLY = 1000;

    // 鑄造一個NFT的價錢
    // 0.000001 eth = 1000 Gwei = 1000000000000
    uint256 public mintPrice = 0.000000 ether;

    // 每個錢包地址最多擁有的NFT數量
    uint256 public maxBalancePerAddress = 1000;

    // 一次能鑄造的NFT支數
    uint256 public maxMint = 1000;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
        ERC721(contractName, contractSymbol)
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    /* 給用戶搶NFT
     * 檢驗功能
     * 1. 一次不能購買超過既定數量
     * 2. 確認目前是否已售罄一空
     * 3. 使得供給量超過上限
     * 4. 確認合約是否開放販售
     * 5. 確認購買者購買完畢後是否會超過每地址持有上限
     * 6. 以太幣夠不夠
     */
    function mintNFT(uint256 tokenQuantity) public payable {
        // 1. 一次不能購買超過既定數量
        require(tokenQuantity <= maxMint, "Attempting to mint too many NFTs.");
        // 2. 確認目前是否已售罄一空
        require(totalSupply() < MAX_SUPPLY, "The sale is over." );
        // 3. 使得供給量超過上限
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Not enough for the supply.");
        // 4. 確認合約是否開放販售
        require(_isSale, "The sale hasn't started yet.");
        // 5. 確認購買者購買完畢後是否會超過每地址持有上限
        require(balanceOf(msg.sender) + tokenQuantity <= maxBalancePerAddress, "You cannot hold tokens more than the specified amount.");
        // 6. 以太幣夠不夠
        require(tokenQuantity * mintPrice <= msg.value, "Insufficient ether.");

        _mintNFT(tokenQuantity);
    }

    // 實際Mint NFT
    function _mintNFT(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function startSale() public onlyOwner { _isSale = true; }
    function closeSale() public onlyOwner { _isSale = false; }
    function toggleSale() public onlyOwner { _isSale = !_isSale; }

    /*
     * setMintPrice: 設定 每個NFT 鑄造單價
     * _mintPrice: based on eth.
     */
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
    /*
     * setMaxMint: 設定單字最多鑄造 NFT 數目
     * _maxMint: an integer.
     */
    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }


    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalancePerAddress(uint256 _maxBalancePerAddress) public onlyOwner {
        maxBalancePerAddress = _maxBalancePerAddress;
    }


    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    // 交易前確認事項
    // 1. 確認目前是否能行交易
    // 2. 確認接收者是否會超過持幣上限
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        // 暫時停止交易.
        require(!_isTransactional, "The transaction is temporarily locked.");
        // 接收者是否會超過持幣上限
        require(balanceOf(to) < maxBalancePerAddress, "The receiver has reached the max balance. ");
    }

}
