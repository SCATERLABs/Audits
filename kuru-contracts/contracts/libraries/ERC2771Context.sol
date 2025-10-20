//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Context variant with ERC2771 support.
 *
 * WARNING: The usage of `delegatecall` in this contract is dangerous and may result in context corruption.
 * Any forwarded request to this contract triggering a `delegatecall` to itself will result in an invalid {_msgSender}
 * recovery.
 */
abstract contract ERC2771Context {
    //in the abtract contract functions they need to be virtual or not ? yes they need to be virtual because they are meant to be overridden in derived contracts.
    //is this an issue to report in the audit?no why make it virtual means without virtual keyword derived contracts cannot override these functions yes or no? yes then it is an issue to report in the audit.is this correct or not? yes it is correct.
    function isTrustedForwarder(address) public view virtual returns (bool) {}
    function _msgData() internal view returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];//here strip last 20 bytes of data if the caller is trusted forwarder
        } else {
            return msg.data;
        }
    }
// this is a function,they need virtual keyword or not? yes they need but why? because they are meant to be overridden in derived contracts.
    function _msgSender() internal view returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextSuffixLength() internal pure returns (uint256) {
        return 20;
    }
}
