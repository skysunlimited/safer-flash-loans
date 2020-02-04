pragma solidity 0.6.0;


import "./IETHFlashBorrower.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/dev-v3.0/contracts/math/SafeMath.sol";



// @notice Any contract that inherits this contract becomes a flash lender of any/all ETH that it holds
// @dev DO NOT USE. This is has not been audited.
contract ETHFlashLender {
    using SafeMath for uint256;
    
    // should never be changed by inheriting contracts
    uint256 private _ethBorrowerDebt;
    
    // internal vars -- okay for inheriting contracts to change
    uint256 internal _ethBorrowFee; // e.g.: 0.003e18 means 0.3% fee
    
    uint256 constant internal ONE = 1e18;

    // @notice Borrow ETH via a flash loan. See ETHFlashBorrower for example.
    // @audit Necessarily violates checks-effects-interactions pattern.
    // @audit - is reentrancy okay here?
    // I would love to NOT have to use the reentrancy guard 
    function ETHFlashLoan(uint256 amount) external {
        
        // record debt
        _ethBorrowerDebt = amount.mul(ONE.add(_ethBorrowFee)).div(ONE);
        
        // send borrower the tokens
        msg.sender.transfer(amount);
        
        // hand over control to borrower
        IETHFlashBorrower(msg.sender).executeOnETHFlashLoan();
        
        // check that debt was fully repaid
        require(_ethBorrowerDebt == 0, "loan not paid back");
    }
    
    // @notice Repay all or part of the loan
    function repayEthDebt() public payable {
        _ethBorrowerDebt = _ethBorrowerDebt.sub(msg.value); // does not allow overpayment
    }
    

    function ethBorrowerDebt() public view returns (uint256) {
        return _ethBorrowerDebt;
    }
    
    function ethBorrowFee() public view returns (uint256) {
        return _ethBorrowFee;
    }
}
