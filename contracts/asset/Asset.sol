// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Snapshot } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import { IAsset } from "../asset/IAsset.sol";
import { IIssuer } from "../issuer/IIssuer.sol";
import { AssetState, InfoEntry } from "../shared/Structs.sol";

contract Asset is IAsset, ERC20Snapshot {

    //------------------------
    //  STATE
    //------------------------
    InfoEntry[] private infoHistory;
    AssetState private state;

    //------------------------
    //  EVENTS
    //------------------------
    event SetOwner(address indexed oldOwner, address indexed newOwner, uint256 timestamp);
    event SetInfo(string info, address setter);
    event SetWhitelistRequiredForTransfer(address indexed caller, bool whitelistRequiredForTransfer, uint256 timestamp);

    //------------------------
    //  CONSTRUCTOR
    //------------------------
    constructor(
        uint256 id,
        address owner,
        address issuer,
        uint256 initialTokenSupply,
        bool whitelistRequiredForTransfer,
        string memory name,
        string memory symbol,
        string memory info
    ) ERC20(name, symbol)
    {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state = AssetState(
            id,
            owner,
            initialTokenSupply,
            whitelistRequiredForTransfer,
            IIssuer(issuer),
            info,
            name,
            symbol
        );
        _mint(owner, initialTokenSupply);
    }

    //------------------------
    //  MODIFIERS
    //------------------------
    modifier walletApproved(address wallet) {
        require(
            !state.whitelistRequiredForTransfer || (state.whitelistRequiredForTransfer && state.issuer.isWalletApproved(wallet)),
            "This functionality is not allowed. Wallet is not approved by the Issuer."
        );
        _;
    }

    modifier ownerOnly() {
        require(
            msg.sender == state.owner,
            "Only asset creator can make this action."
        );
        _;
    }

    //------------------------
    //  IAsset IMPL
    //------------------------
    function setOwner(address newOwner)
        external
        override
        ownerOnly
    {
        state.owner = newOwner;
        emit SetOwner(msg.sender, newOwner, block.timestamp);
    }

    function setInfo(string memory info) external ownerOnly {
        infoHistory.push(InfoEntry(
            info,
            block.timestamp
        ));
        state.info = info;
        emit SetInfo(info, msg.sender);
    }

    function setWhitelistRequiredForTransfer(bool whitelistRequiredForTransfer) external ownerOnly {
        state.whitelistRequiredForTransfer = whitelistRequiredForTransfer;
        emit SetWhitelistRequiredForTransfer(msg.sender, whitelistRequiredForTransfer, block.timestamp);
    }

    function totalShares() external view override returns (uint256) {
        return totalSupply();
    }

    function getState() external view override returns (AssetState memory) {
        return state;
    }

    function getInfoHistory() external view override returns (InfoEntry[] memory) {
        return infoHistory;
    }

    //------------------------
    //  ERC20 OVERRIDES
    //------------------------
    function transfer(address recipient, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        walletApproved(sender)
        walletApproved(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        walletApproved(_msgSender())
        walletApproved(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    //------------------------
    //  ERC20Snapshot
    //------------------------
    function snapshot() external override returns (uint256) {
        return _snapshot();
    }

}
