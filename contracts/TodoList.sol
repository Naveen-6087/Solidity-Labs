// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract TodoList {
    struct Task {
        uint256 id;
        string description;
        bool completed;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public nextId;

    function addTask(string memory _description) public {
        tasks[nextId] = Task(nextId, _description, false);
        nextId++;
    }

    function deleteTask(uint256 _id) public {
        delete tasks[_id];
    }

    function getTask(uint256 _id) public view returns (string memory description, bool completed) {
        Task memory task = tasks[_id];
        return (task.description, task.completed);
    }

    function toggleComplete(uint256 _id) public {
        tasks[_id].completed = !tasks[_id].completed;
    }
}
