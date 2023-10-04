module stake_addr::Stake {
    use std::signer;
    use std::vector;
    use aptos_std::table::{Self, Table};
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    
    struct StakedAmount has key {
        stake: Table<address, u64>,
        staked_users: vector<address>,
        total_staked_amount: u64,
        signer_cap: account::SignerCapability
    }

    const EUSER_NOT_STAKED: u64 = 1;
    const ENOT_ENOUGH_AVALIABLE_STAKED_AMOUNT: u64 = 2;

    fun init_module(signer_account: &signer) {
 
        let (_resource, signer_cap) = account::create_resource_account(signer_account, vector::empty());
        let resource_signer_addr = account::create_signer_with_capability(&signer_cap);

        coin::register<AptosCoin>(&resource_signer_addr);

        move_to(signer_account, StakedAmount {
            stake: table::new(),
            staked_users: vector::empty(),
            total_staked_amount: 0,
            signer_cap: signer_cap,
        });
    }

    public entry fun stake(account: &signer, amount: u64) acquires StakedAmount {
        let staked_amount = borrow_global_mut<StakedAmount>(@stake_addr);
        let signer_addr = signer::address_of(account);

        let resource_signer_addr = account::create_signer_with_capability(&staked_amount.signer_cap);

        coin::transfer<AptosCoin>(account, signer::address_of(&resource_signer_addr), amount);

        staked_amount.total_staked_amount = staked_amount.total_staked_amount + amount;
        vector::push_back(&mut staked_amount.staked_users, signer_addr);
        
        let already_staked = table::contains(&staked_amount.stake, signer_addr);

        if (already_staked) {
            let staked = table::borrow(&staked_amount.stake, signer_addr);
            let new_staked_amount = *staked + amount;
            table::upsert(&mut staked_amount.stake, signer_addr, new_staked_amount);
        } else {
            table::add(&mut staked_amount.stake, signer_addr, amount);
        }
    }

    public entry fun unstake(account: &signer, amount: u64) acquires StakedAmount {
        let staked_amount = borrow_global_mut<StakedAmount>(@stake_addr);
        let receiver_addr = signer::address_of(account);

        let resource_signer_addr = account::create_signer_with_capability(&staked_amount.signer_cap);

        assert!(table::contains(&staked_amount.stake, receiver_addr), EUSER_NOT_STAKED);
        
        let staked = table::borrow(&staked_amount.stake, receiver_addr);
        assert!(*staked >= amount, ENOT_ENOUGH_AVALIABLE_STAKED_AMOUNT);

        coin::transfer<AptosCoin>(&resource_signer_addr, receiver_addr, amount);
        staked_amount.total_staked_amount = staked_amount.total_staked_amount - amount;
        
        let staked = table::borrow(&staked_amount.stake, receiver_addr);
        let new_staked_amount = *staked - amount;
        table::upsert(&mut staked_amount.stake, receiver_addr, new_staked_amount);
        if (new_staked_amount == 0) {
            table::remove(&mut staked_amount.stake, receiver_addr);
            let (_bool, index) = vector::index_of(&staked_amount.staked_users, &receiver_addr);
            vector::remove(&mut staked_amount.staked_users, index);
        }
    } 

    #[view]
    public fun get_total_staked_amount(): u64 acquires StakedAmount {
        let data = borrow_global<StakedAmount>(@stake_addr);

        data.total_staked_amount
    }

    #[view]
    public fun get_stake_amount_for_address(addr: address): u64 acquires StakedAmount {
        let staked_amount = borrow_global<StakedAmount>(@stake_addr);
        let amount = table::borrow(&staked_amount.stake, addr);
        *amount
    }

    #[view]
    public fun get_all_staked_user(): vector<address> acquires StakedAmount {
        borrow_global<StakedAmount>(@stake_addr).staked_users
    }
}