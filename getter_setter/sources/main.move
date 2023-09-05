module addr::setter {
    use std::string;
    use std::signer;

    struct Message has key {
        message: string::String,
    }

    public entry fun set_message(account: signer, message: string::String) acquires Message {
        let addr = signer::address_of(&account);

        if(!exists<Message>(addr)) {
            move_to(&account, Message {
                message: message
            })
        }else {
            borrow_global_mut<Message>(addr).message = message;
        }
    }

    #[view]
    public fun get_message(account: address): string::String acquires Message {
        borrow_global<Message>(account).message
    }

    #[test(account = @0x1)]
    public fun set_message_test(account: signer) acquires Message {
        let addr = signer::address_of(&account);

        set_message(account, string::utf8(b"Hello"));

        assert!(get_message(addr) == string::utf8(b"Hello"), 0);
    }

}