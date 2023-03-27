// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BAY is Ownable {
    struct Session {
        uint startTime;
        uint closedTime;
    }

    enum AttendanceStatus {before, present, late, absent}
    struct Member {
        bool isRegistered;
        AttendanceStatus attendance;
        uint16 presentCount;
        uint16 lateCount;
        uint16 absentCount;
    }

    address[] private memberAddressList;
    mapping(address => Member) private members;

    Session[] public sessionList;

    bool attendanceInitialized = true;

    event MemberRegistered(address indexed member);
    event MemberJoinedSession(address indexed member);

    constructor() {
        registerMember(msg.sender);
    }

    function changePresident(address _newPresident) public onlyOwner {
        require(owner() != _newPresident, "Already is president");
        transferOwnership(_newPresident);
    }

    function registerMember(address _member) public onlyOwner {
        require(!members[_member].isRegistered, "Member is already registered");
        members[_member].isRegistered = true;
        members[_member].attendance = AttendanceStatus.before;
        memberAddressList.push(_member);
        emit MemberRegistered(_member);
    }

    function updateAttendanceCount(address _member) public onlyOwner {
        require(members[_member].attendance != AttendanceStatus.before);
        if (members[_member].attendance == AttendanceStatus.late) {
            members[_member].lateCount++;
        }
        else if (members[_member].attendance == AttendanceStatus.absent) {
            members[_member].absentCount++;
        }
        else {
            members[_member].presentCount++;
        }
    }

    modifier isMember(address _address) {
        checkMember(_address);
        _;
    }

    function checkMember(address _address) public view {
        bool isMemb = false;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (memberAddressList[i] == _address) {
                isMemb = true;
            }
        }
        require(isMemb);
    }

    function createSession() public onlyOwner sessionNotRunning {
        require(attendanceInitialized);
        sessionList.push(Session(block.timestamp, 0));
        joinSession();
        attendanceInitialized = false;
    }

    function closeSession() public onlyOwner sessionRunning {
        sessionList[sessionList.length-1].closedTime = block.timestamp;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.before) {
                members[memberAddressList[i]].attendance = AttendanceStatus.absent;
            }
            updateAttendanceCount(memberAddressList[i]);
        }
    }

    function initAttendance() public onlyOwner sessionNotRunning {
        for (uint i = 0; i < memberAddressList.length; i++) {
            members[memberAddressList[i]].attendance = AttendanceStatus.before;
        }
        attendanceInitialized = true;
    }

    function joinSession() public isMember(msg.sender) sessionRunning {
        require(members[msg.sender].isRegistered, "Member is not registered");
        require(members[msg.sender].attendance == AttendanceStatus.before, "Member has already checked in");
        if (block.timestamp > sessionList[sessionList.length-1].startTime + 5 minutes) {
            members[msg.sender].attendance = AttendanceStatus.late;
        }
        else {
            members[msg.sender].attendance = AttendanceStatus.present;
        }
        emit MemberJoinedSession(msg.sender);
    }

    function sessionIsRunning() public view returns(bool) {
        if (sessionList.length == 0) {
            return false;
        }
        return (sessionList[sessionList.length-1].closedTime == 0);
    }

    modifier sessionRunning() {
        require(sessionIsRunning(), "No session is running");
        _;
    }

    modifier sessionNotRunning() {
        require(!sessionIsRunning(), "Session is now running");
        _;
    }

    function getPresident() public view returns(address) {
        return owner();
    }

    function getMember(address _member) public view returns (Member memory) {
        return members[_member];
    }

    function getmemberAddressList() public view returns (address[] memory) {
        return memberAddressList;
    }

    function getPresentMembers() public view returns (address[] memory) {
        uint presentCount = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.present) {
                presentCount++;
            }
        }

        address[] memory presentMembers = new address[](presentCount);
        uint index = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.present) {
                presentMembers[index] = memberAddressList[i];
                index++;
            }
        }
        return presentMembers;
    }

    function getLateMembers() public view returns (address[] memory) {
        uint lateCount = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.late) {
                lateCount++;
            }
        }

        address[] memory lateMembers = new address[](lateCount);
        uint index = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.late) {
                lateMembers[index] = memberAddressList[i];
                index++;
            }
        }
        return lateMembers;
    }

    function getAbsentMembers() public view returns (address[] memory) {
        uint absentCount = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.absent) {
                absentCount++;
            }
        }

        address[] memory absentMembers = new address[](absentCount);
        uint index = 0;
        for (uint i = 0; i < memberAddressList.length; i++) {
            if (members[memberAddressList[i]].attendance == AttendanceStatus.absent) {
                absentMembers[index] = memberAddressList[i];
                index++;
            }
        }
        return absentMembers;
    }

    function getSessionList() public view returns (Session[] memory){
        return sessionList;
    }
}