// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
/// @title  Student Attendance Management
/// @notice A simple smart contract for a college lab demonstration.
///         The account that deploys the contract becomes the "teacher".
contract StudentAttendance {
 
    // -----------------------------------------------------------------
    // State variables
    // -----------------------------------------------------------------
 
    address public teacher;        // The account that deployed the contract
    uint256 public studentCount;   // How many students have been registered
 
    // -----------------------------------------------------------------
    // Structs
    // -----------------------------------------------------------------
 
    // Basic information about one student
    struct Student {
        string name;
        bool isRegistered;
    }
 
    // Attendance for one student on one date
    struct AttendanceRecord {
        bool present;   // true = present, false = absent
        bool marked;    // true = this date has been recorded
    }
 
    // -----------------------------------------------------------------
    // Mappings
    // -----------------------------------------------------------------
 
    // rollNumber => student details
    mapping(uint256 => Student) private students;
 
    // rollNumber => date => attendance record
    mapping(uint256 => mapping(string => AttendanceRecord)) private attendance;
 
    // rollNumber => list of dates on which attendance was marked
    // (needed so we can calculate totals later)
    mapping(uint256 => string[]) private studentDates;
 
    // -----------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------
 
    event StudentRegistered(uint256 indexed rollNumber, string name);
    event AttendanceMarked(uint256 indexed rollNumber, string date, bool present);
 
    // -----------------------------------------------------------------
    // Modifiers
    // -----------------------------------------------------------------
 
    // Allows only the teacher (the deployer) to run the function
    modifier onlyTeacher() {
        require(msg.sender == teacher, "Only the teacher can do this");
        _;
    }
 
    // -----------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------
 
    // Runs once when the contract is deployed.
    // Whoever deploys the contract becomes the teacher.
    constructor() {
        teacher = msg.sender;
    }
 
    // -----------------------------------------------------------------
    // Functions
    // -----------------------------------------------------------------
 
    /// @notice Register a new student. Only the teacher can call this.
    /// @param rollNumber The student's roll number (must be unique)
    /// @param name The student's name
    function registerStudent(uint256 rollNumber, string memory name) public onlyTeacher {
        require(!students[rollNumber].isRegistered, "Student already registered");
        require(bytes(name).length > 0, "Name cannot be empty");
 
        students[rollNumber] = Student(name, true);
        studentCount++;
 
        emit StudentRegistered(rollNumber, name);
    }
 
    /// @notice Mark a student present or absent for a given date.
    ///         Only the teacher can call this. Duplicate entries are blocked.
    /// @param rollNumber The student's roll number
    /// @param date The date as text, e.g. "2026-11-25"
    /// @param present true = present, false = absent
    function markAttendance(uint256 rollNumber, string memory date, bool present) public onlyTeacher {
        require(students[rollNumber].isRegistered, "Student is not registered");
        require(!attendance[rollNumber][date].marked, "Attendance already marked for this date");
 
        attendance[rollNumber][date] = AttendanceRecord(present, true);
        studentDates[rollNumber].push(date);
 
        emit AttendanceMarked(rollNumber, date, present);
    }
 
    /// @notice Get the attendance summary (total, attended, percentage).
    ///         A student can call this with their own roll number;
    ///         the teacher can call it for any student.
    /// @param rollNumber The student's roll number
    function getAttendanceSummary(uint256 rollNumber)
        public
        view
        returns (uint256 totalClasses, uint256 classesAttended, uint256 percentage)
    {
        require(students[rollNumber].isRegistered, "Student is not registered");
 
        string[] storage dates = studentDates[rollNumber];
        totalClasses = dates.length;
 
        for (uint256 i = 0; i < dates.length; i++) {
            if (attendance[rollNumber][dates[i]].present) {
                classesAttended++;
            }
        }
 
        if (totalClasses == 0) {
            percentage = 0;
        } else {
            percentage = (classesAttended * 100) / totalClasses;
        }
    }
 
    /// @notice Check whether a student was present on one specific date.
    ///         Used by the teacher (and anyone) to verify a single day.
    /// @param rollNumber The student's roll number
    /// @param date The date to check, e.g. "2026-11-25"
    function getAttendanceOnDate(uint256 rollNumber, string memory date)
        public
        view
        returns (bool present, bool marked)
    {
        require(students[rollNumber].isRegistered, "Student is not registered");
 
        AttendanceRecord memory record = attendance[rollNumber][date];
        return (record.present, record.marked);
    }
 
    /// @notice Get the registered name of a student.
    /// @param rollNumber The student's roll number
    function getStudentName(uint256 rollNumber) public view returns (string memory) {
        require(students[rollNumber].isRegistered, "Student is not registered");
        return students[rollNumber].name;
    }
}
