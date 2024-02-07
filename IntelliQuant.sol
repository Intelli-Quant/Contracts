// Web: https://intelliquantcoin.com
// Telegram: https://t.me/IntelliQuantVerify/3
// Docs: https://docs.intelliquantcoin.com
// Twitter: https://twitter.com/IntelliQuant
//
//       $$$$$                                                                                
//       $:::$                                                                                
//   $$$$$:::$$$$$$ IIIIIIIIIINNNNNNNN        NNNNNNNN     QQQQQQQQQ     UUUUUUUU     UUUUUUUU
// $$::::::::::::::$I::::::::IN:::::::N       N::::::N   QQ:::::::::QQ   U::::::U     U::::::U
//$:::::$$$$$$$::::$I::::::::IN::::::::N      N::::::N QQ:::::::::::::QQ U::::::U     U::::::U
//$::::$       $$$$$II::::::IIN:::::::::N     N::::::NQ:::::::QQQ:::::::QUU:::::U     U:::::UU
//$::::$              I::::I  N::::::::::N    N::::::NQ::::::O   Q::::::Q U:::::U     U:::::U 
//$::::$              I::::I  N:::::::::::N   N::::::NQ:::::O     Q:::::Q U:::::D     D:::::U 
//$:::::$$$$$$$$$     I::::I  N:::::::N::::N  N::::::NQ:::::O     Q:::::Q U:::::D     D:::::U 
// $$::::::::::::$$   I::::I  N::::::N N::::N N::::::NQ:::::O     Q:::::Q U:::::D     D:::::U 
//   $$$$$$$$$:::::$  I::::I  N::::::N  N::::N:::::::NQ:::::O     Q:::::Q U:::::D     D:::::U 
//            $::::$  I::::I  N::::::N   N:::::::::::NQ:::::O     Q:::::Q U:::::D     D:::::U 
//            $::::$  I::::I  N::::::N    N::::::::::NQ:::::O  QQQQ:::::Q U:::::D     D:::::U 
//$$$$$       $::::$  I::::I  N::::::N     N:::::::::NQ::::::O Q::::::::Q U::::::U   U::::::U 
//$::::$$$$$$$:::::$II::::::IIN::::::N      N::::::::NQ:::::::QQ::::::::Q U:::::::UUU:::::::U 
//$::::::::::::::$$ I::::::::IN::::::N       N:::::::N QQ::::::::::::::Q   UU:::::::::::::UU  
// $$$$$$:::$$$$$   I::::::::IN::::::N        N::::::N   QQ:::::::::::Q      UU:::::::::UU    
//      $:::$       IIIIIIIIIINNNNNNNN         NNNNNNN     QQQQQQQQ::::QQ      UUUUUUUUU      
//      $$$$$                                                      Q:::::Q                    
//  
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IntelliQuant is ERC20, Ownable {
    event BuyTaxChanged(address indexed, uint256 amount);
    event SellTaxChanged(address indexed, uint256 amount);
    event TransferTaxChanged(address indexed, uint256 amount);
    event AddedTaxFreeAddress(address indexed);
    address public taxWallet;
    address public transferTaxWallet;
    address public uniswapV2Pair;
    uint256 public buyTaxPercentage;
    uint256 public sellTaxPercentage;
    uint256 public transferTaxPercentage;

    mapping(address => bool) public taxFreeAddresses;

    constructor() ERC20("IntelliQuant", "INQU") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000_000 * 10**18);
        taxFreeAddresses[address(0)] = true;
        taxFreeAddresses[msg.sender] = true;
        transferTaxPercentage = 25;
        buyTaxPercentage = 40;
        sellTaxPercentage = 40;
        uniswapV2Pair = address(0);
        transferTaxWallet = msg.sender;
        taxWallet = 0xca70AAc50D992bcE1Bd1561aa94Ab654B444a7Cb;
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        
        if (!taxFreeAddresses[from] && !taxFreeAddresses[to]) {
            if (from == uniswapV2Pair) {
                //This means that the user is buying $INQU tokens
                uint256 buyTaxAmount = (value / 100) * buyTaxPercentage;
                uint256 tokensLeft = value - buyTaxAmount;
                super._update(from, taxWallet, buyTaxAmount);
                super._update(from, to, tokensLeft);
            } else if (to == uniswapV2Pair) {
                //This means that the user wants to sell $INQU tokens
                uint256 sellTaxAmount = (value / 100) * sellTaxPercentage;
                uint256 tokensLeft = value - sellTaxAmount;
                super._update(from, taxWallet, sellTaxAmount);
                super._update(from, to, tokensLeft);
            } else {
                uint256 transferTaxAmount = (value / 100) *
                    transferTaxPercentage;
                uint256 tokensLeft = value - transferTaxAmount;
                super._update(from, transferTaxWallet, transferTaxAmount);
                super._update(from, to, tokensLeft);
            }
        } else{
            //Tax free transfer 
            super._update(from, to, value);
        }
    }

    function changeTransferTax(uint256 _taxAmount) external onlyOwner {
        require(
            _taxAmount <= 25,
            "The transfer tax Amount must not be greater than 25%"
        );
        transferTaxPercentage = _taxAmount;
        emit TransferTaxChanged(msg.sender, _taxAmount);
    }

    function changeSelltax(uint256 _taxAmount) external onlyOwner {
        require(
            _taxAmount <= 40,
            "The sell tax Amount must not be greater than 40% - for initial launch"
        );
        sellTaxPercentage = _taxAmount;
        emit SellTaxChanged(msg.sender, _taxAmount);
    }

    function changeBuyTax(uint256 _taxAmount) external onlyOwner {
        require(
            _taxAmount <= 40,
            "The buy tax Amount must not be greater than 40% - for initial launch"
        );
        buyTaxPercentage = _taxAmount;
        emit BuyTaxChanged(msg.sender, _taxAmount);
    }

    function changeTaxWallet(address _wallet) external onlyOwner {
        taxWallet = _wallet;
    }

    function changeUniwapV2PairAddress(address _uniswapV2Pair)
        public
        onlyOwner
    {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function addToTaxFreeList(address _user) external onlyOwner {
        taxFreeAddresses[_user] = true;
        emit AddedTaxFreeAddress(_user);
    }
    function changeTransferTaxWalletAddress(address _wallet)external onlyOwner{
        transferTaxWallet = _wallet;
    }
}
