pragma solidity ^0.4.15;


import 'zeppelin-solidity/contracts/math/SafeMath.sol';


contract Membership {
    using SafeMath for uint256;

    enum MemberTypes {NOT_MEMBER, EXISTING_MEMBER, DELEGATE, WHITELISTER}

    struct Member {
        MemberTypes memberType;
        uint256 whitelisted;
        bool paid;
    }

    mapping (address => Member) public members;
    uint256 allMembers;

    // member => (whitelister => time)
    // mapping (address => mapping(address => uint256)) public whitelistMembers;

    function() {
        payMembership();
    }

    modifier onlyMember() {
        require(members[msg.sender].memberType == MemberTypes.EXISTING_MEMBER
            || members[msg.sender].memberType == MemberTypes.WHITELISTER
            || members[msg.sender].memberType == MemberTypes.DELEGATE); // TODO: ?
        _;
    }

    modifier onlyDelegate() {
        require(members[msg.sender].memberType == MemberTypes.DELEGATE);
        _;
    }

    modifier onlyWhitelister() {
        require(members[msg.sender].memberType == MemberTypes.WHITELISTER);
        _;
    }


    function requestMembership() public {
        members[msg.sender] = Member(MemberTypes.NOT_MEMBER, 0, false);
    }

    function whitelistMember(address addrs) public onlyWhitelister {
        // TODO: prevent duplication
        members[addrs].whitelisted = members[addrs].whitelisted.add(1);

        if(members[addrs].whitelisted >= 2 && members[addrs].paid) {
            concludeJoining(addrs);
        }
    }

    function addWhitelister(address addrs) public onlyDelegate {
        members[addrs] = Member(MemberTypes.WHITELISTER, 0, false);
    }

    function removeWhitelister(address addrs) public onlyDelegate {
        require(members[addrs].memberType == MemberTypes.WHITELISTER);
        delete members[addrs];
    }

    function payMembership() public payable {
        // TODO: check msg.value
        members[msg.sender].paid = true;
        if(members[msg.sender].whitelisted >= 2) {
            concludeJoining(msg.sender);
        }
    }

    function leaveDAA() public {
        if (members[msg.sender].memberType == MemberTypes.DELEGATE) {
            // TODO: For delegate that should only be possible when also proposing new GA date
        }

        delete members[msg.sender];
        allMembers = allMembers.sub(1);
    }

    function getAllMembersCount() public constant returns (uint256) {
        return allMembers;
    }

    function removeMemberThatDidntPay(address addrs) internal {
        delete members[addrs];
    }

    function concludeJoining(address addrs) private {
        members[addrs].memberType = MemberTypes.EXISTING_MEMBER;
        allMembers = allMembers.add(1);
    }

}