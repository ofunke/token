// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

// Declare the external oracle interface
interface IExternalPriceOracle {
    function latestAnswer() external view returns (int256);
}

contract AlgorithmicToken is Initializable, 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    ERC20PermitUpgradeable, 
    ERC20VotesUpgradeable, 
    UUPSUpgradeable, 
    OwnableUpgradeable, 
    PausableUpgradeable
{
    address public customOracle;
    address public externalOracle;
    uint256 public peg;

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _customOracle) public initializer {
        __ERC20_init("USD ColLateral", "USDc");
        __ERC20Burnable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("Algorithmic Token");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        peg = 1e18;
        customOracle = _customOracle;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updatePeg(uint256 newPeg) external onlyOwner {
        peg = newPeg;
    }

    function updateCustomOracle(address newCustomOracle) external onlyOwner {
        customOracle = newCustomOracle;
    }

    function updateExternalOracle(address newExternalOracle) external onlyOwner {
        externalOracle = newExternalOracle;
    }

    function fetchCustomPrice() public view returns (uint256) {
        require(customOracle != address(0), "Custom Oracle not set");
        (bool success, bytes memory data) = customOracle.staticcall(abi.encodeWithSignature("latestPrice()"));
        require(success, "Custom Oracle call failed");
        return abi.decode(data, (uint256));
    }

    function fetchExternalPrice() public view returns (uint256) {
        require(externalOracle != address(0), "External Oracle not set");
        int256 price = IExternalPriceOracle(externalOracle).latestAnswer();
        require(price > 0, "Invalid price from external oracle");
        return uint256(price);
    }

    function stabilize() external whenNotPaused {
        uint256 currentPrice;

        if (customOracle != address(0)) {
            currentPrice = fetchCustomPrice();
        } else if (externalOracle != address(0)) {
            currentPrice = fetchExternalPrice();
        } else {
            revert("No valid oracle available");
        }

        require(currentPrice > 0, "Invalid price");

        if (currentPrice > peg) {
            uint256 excess = (currentPrice - peg) * totalSupply() / peg;
            _mint(address(this), excess);
        } else if (currentPrice < peg) {
            uint256 deficit = (peg - currentPrice) * totalSupply() / peg;
            _burn(address(this), deficit);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, value);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}