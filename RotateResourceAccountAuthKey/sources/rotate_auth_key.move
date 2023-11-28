module addr::rotate {
    use std::signer;
    use std::table::{Self, Table};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::resource_account;

    struct ResourceAccountData has key {
        resource_account: Table<address, address>,
    }

    struct SignerCap has key {
        cap: Table<address, SignerCapability>,
    }

    fun init_module(account: &signer) {
        move_to(account, ResourceAccountData {
            resource_account: table::new(),
        });

        move_to(account, SignerCap {
            cap: table::new(),
        });
    }

    // This function utilize create_resouce_account method from resource_account module in aptos_framework
    // It create a resource account and set the auth_key to the provided key.
    public entry fun create_resource_account(account: &signer, auth_key: vector<u8>, seed: vector<u8>) acquires ResourceAccountData {
        resource_account::create_resource_account(account, seed, auth_key);
        let resource_account_address = account::create_resource_address(&signer::address_of(account), seed);

        let resource_account_data = borrow_global_mut<ResourceAccountData>(@addr);
        table::add(&mut resource_account_data.resource_account, signer::address_of(account), resource_account_address); 
    }

    // This function utilize create_resource_account method from account mdoule in aptos_framework
    // It creates the resource account and claims signer_cap and set auth_key to 0x0
    public entry fun create_resource_account_and_claim_signer_cap(account: &signer, seed: vector<u8>) acquires ResourceAccountData, SignerCap {
        let (resource_account_signer, resource_signer_cap) = account::create_resource_account(account, seed);
        let resource_account_address = signer::address_of(&resource_account_signer);

        let resource_account_data = borrow_global_mut<ResourceAccountData>(@addr);
        let resource_signer_cap_data = borrow_global_mut<SignerCap>(@addr);

        table::add(&mut resource_account_data.resource_account, signer::address_of(account), resource_account_address);
        table::add(&mut resource_signer_cap_data.cap, resource_account_address, resource_signer_cap);
    }

    public entry fun offer_signer_cap(account: &signer, recipient_addr: address, signer_capability_sig_bytes: vector<u8>, account_public_key_bytes: vector<u8>) {
        account::offer_signer_capability(account, signer_capability_sig_bytes, 0, account_public_key_bytes, recipient_addr);
    }

    public entry fun offer_rotation_cap(account: &signer, recipient_addr: address, rotation_capability_sig_bytes: vector<u8>, account_public_key_bytes: vector<u8>) {
        account::offer_rotation_capability(account, rotation_capability_sig_bytes, 0, account_public_key_bytes, recipient_addr);
    }

    public entry fun retrive_signer_cap(account: &signer) acquires ResourceAccountData, SignerCap {
        let source_addr = signer::address_of(account);
        let resource_account_data = borrow_global<ResourceAccountData>(@addr);
        let resource_address = *table::borrow(&resource_account_data.resource_account, source_addr);

        let resource_signer_cap_data = borrow_global_mut<SignerCap>(@addr);

        let resource_signer = account::create_authorized_signer(account, resource_address);

        let signer_cap = resource_account::retrieve_resource_account_cap(&resource_signer, source_addr);
        table::add(&mut resource_signer_cap_data.cap, resource_address, signer_cap);
    }

    #[view]
    public fun get_resource_account(addr: address): address acquires ResourceAccountData {
        let resource_account_data = borrow_global<ResourceAccountData>(@addr);

        *table::borrow(&resource_account_data.resource_account, addr)
    }

    #[view]
    public fun get_auth_key(account_address: address): vector<u8> {
        account::get_authentication_key(account_address)
    }

    #[view]
    public fun is_signer_cap_offered(addr: address): bool {
        account::is_signer_capability_offered(addr)
    }

    #[view]
    public fun is_rotation_cap_offered(addr: address): bool {
        account::is_rotation_capability_offered(addr)
    }

    #[view]
    public fun get_signer_capability_offer_for(addr: address): address {
        account::get_signer_capability_offer_for(addr)
    }

    #[view]
    public fun get_rotation_capability_offer_for(addr: address): address {
        account::get_rotation_capability_offer_for(addr)
    }

}