module todo_address::todolist {

    use std::signer;
    use aptos_framework::event;
    use aptos_framework::account;
    use std::string::String;
    use std::vector;
    use aptos_std::table::{Self, Table};

    const E_IS_NOT_INITIALIZED: u64 = 1;
    const E_TASK_DOES_NOT_EXISTS: u64 = 2;
    const E_TASK_IS_COMPLETED: u64 = 3;

    struct Todo has key, store {
        task: Table<u64, Task>,
        set_task_event: event::EventHandle<Task>,
        task_counter: u64
    }

    struct Task has store, drop, copy {
        task_id: u64,
        created_by: address,
        content: String,
        status: bool,
    }

    public entry fun create_list(account: &signer) {
        let todo_list = Todo {
            task: table::new(),
            set_task_event: account::new_event_handle<Task>(account),
            task_counter: 0,
        };

        move_to(account, todo_list);
    }

    public entry fun create_todo(account: &signer, content: String) acquires Todo {
        let signer_address = signer::address_of(account);
        assert!(exists<Todo>(signer_address), E_IS_NOT_INITIALIZED);
        
        let todo_list = borrow_global_mut<Todo>(signer_address);
        let counter = todo_list.task_counter + 1;

        let task = Task {
            task_id: counter,
            created_by: signer_address,
            content: content,
            status: false
        };

        table::upsert(&mut todo_list.task, counter, task);
        todo_list.task_counter = counter;

        event::emit_event<Task>(&mut borrow_global_mut<Todo>(signer_address).set_task_event, task);
    }


    public entry fun mark_complete_task(account: &signer, task_id: u64) acquires Todo {
        let signer_address = signer::address_of(account);
        assert!(exists<Todo>(signer_address), E_IS_NOT_INITIALIZED);

        let todo_list = borrow_global_mut<Todo>(signer_address);
        assert!(table::contains(&todo_list.task, task_id), E_TASK_DOES_NOT_EXISTS);

        let task = table::borrow_mut(&mut todo_list.task, task_id);
        assert!(task.status == false, E_TASK_IS_COMPLETED);
        task.status = true;
    }

    #[view]
    public fun get_todos_count(account: address): u64 acquires Todo {
        borrow_global<Todo>(account).task_counter
    }

    #[view]
    public fun get_task_detail(account: address): vector<Task> acquires Todo {
        let todo = borrow_global<Todo>(account);

        let vec = vector::empty<Task>();

        let task_count = todo.task_counter;
        
        let i = 1;
        while(i <= task_count) {
            let task = *table::borrow(&todo.task, i);
            vector::push_back(&mut vec, task);
            i = i + 1;
        };

        vec
    }
}