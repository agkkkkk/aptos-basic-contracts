module  multisend::multisend {
    use std::signer;
    use std::vector;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account;
    use aptos_std::event::{Self, EventHandle};

    const ENOT_OWNER: u64 = 1;
    const EVECTOR_LENGTH_MISMATCH: u64 = 2;

    struct FeeManagement has key {
        fee: u64,
        owner: address,
    }

    struct Transfer has key {
        transfer_event: EventHandle<TransferEvent>,
    }

    struct TransferEvent has store, drop {
        addresses: vector<address>,
        amounts: vector<u64>,
        total_amount: u64,
        fee_paid: u64
    }

    fun init_module(account: &signer) {
        move_to(account, FeeManagement {
            fee: 5,
            owner: @owner,
        });

        move_to(account, Transfer {
            transfer_event: account::new_event_handle<TransferEvent>(account),
        });
    }

    public entry fun update_owner(account: &signer, new_owner: address) acquires FeeManagement {
        let addr = signer::address_of(account);
        let fee_management = borrow_global_mut<FeeManagement>(@multisend);

        assert!(fee_management.owner == addr, ENOT_OWNER);
        fee_management.owner = new_owner;
    }

    public entry fun update_fee(account: &signer, fee: u64) acquires FeeManagement {
        let addr = signer::address_of(account);
        let fee_management = borrow_global_mut<FeeManagement>(@multisend);

        assert!(fee_management.owner == addr, ENOT_OWNER);
        fee_management.fee = fee;
    }

    public entry fun multisend(account: &signer, addresses: vector<address>, amounts: vector<u64>) acquires FeeManagement, Transfer {
        let len = vector::length(&addresses);
        assert!(len == vector::length(&amounts), EVECTOR_LENGTH_MISMATCH);

        let fee_management = borrow_global<FeeManagement>(@multisend);
        let total_amount: u64 = 0;

        let i = 0;

        while(i < len) {
            let addr = *vector::borrow(&addresses, i);
            let amount = *vector::borrow(&amounts, i);

            total_amount = total_amount + amount;
            coin::transfer<AptosCoin>(account, addr, amount);

            i = i + 1;
        };

        let fee = total_amount * fee_management.fee / 100;
        coin::transfer<AptosCoin>(account, fee_management.owner, fee);

        let transfer_data = borrow_global_mut<Transfer>(@multisend);
        event::emit_event(&mut transfer_data.transfer_event, TransferEvent {
            addresses,
            amounts,
            total_amount,
            fee_paid: fee,
        });
    }

    #[view]
    public fun get_fee(): u64 acquires FeeManagement {
        borrow_global<FeeManagement>(@multisend).fee
    }
}