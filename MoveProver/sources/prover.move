module prover::test {
    use std::signer;
    use std::string::String;

    struct AccountData has key {
        name: String,
        age: u8,
    }

    fun set_account_data(account: &signer, name: String, age: u8) acquires AccountData {
        let addr = signer::address_of(account);
        if (exists<AccountData>(addr)) {
            let data = borrow_global_mut<AccountData>(addr);
            data.name = name;
            data.age = age;
        } else {
            move_to(account, AccountData {
                name,
                age
            });
        }
    }

    spec module {
        pragma aborts_if_is_strict;
    }

    spec set_account_data {
        let addr = signer::address_of(account);
        aborts_if age > MAX_U8;

        ensures global<AccountData>(addr).name == name;
        ensures global<AccountData>(addr).age == age;
    }
    
}