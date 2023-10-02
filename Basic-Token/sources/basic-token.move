module token_addr::BasicToken {
    use std::string::{Self, utf8};
    use std::signer;
    use std::option;
    use aptos_framework::coin;

    struct BasicToken has key {}

    struct CoinCapabilities has key {
        mint_cap: coin::MintCapability<BasicToken>,
        burn_cap: coin::BurnCapability<BasicToken>,
        freeze_cap: coin::FreezeCapability<BasicToken>,
    }

    const ENOT_OWNER: u64 = 0;
    
    fun init_module(account: &signer) {
        let addr = signer::address_of(account);
        assert!(addr == @token_addr, ENOT_OWNER);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<BasicToken>(
            account,
            utf8(b"BASIC TOKEN"),
            utf8(b"BT"),
            8,
            true
        );

        move_to(account, CoinCapabilities { mint_cap, burn_cap, freeze_cap });
    }

    public entry fun register(account: &signer) {
        coin::register<BasicToken>(account);
    }

    public entry fun mint(account: &signer, amount: u64) acquires CoinCapabilities {
        let addr = signer::address_of(account);

        let mint = &borrow_global<CoinCapabilities>(@token_addr).mint_cap;
        let coins = coin::mint<BasicToken>(amount, mint);
        coin::deposit<BasicToken>(addr, coins);
    }

    public entry fun burn(account: &signer, amount: u64) acquires CoinCapabilities {
        
        let coins = coin::withdraw<BasicToken>(account, amount);
        let burn = &borrow_global<CoinCapabilities>(@token_addr).burn_cap;
        coin::burn<BasicToken>(coins, burn);
        
    }

    #[view]
    public fun get_balance(addr: address): u64 {
        coin::balance<BasicToken>(addr)
    }

    #[view]
    public fun total_supply(): u128 {
        let total_supply = coin::supply<BasicToken>();
        *option::borrow<u128>(&total_supply)
    }

    #[view]
    public fun token_name(): string::String {
        coin::name<BasicToken>()
    }

    #[view]
    public fun token_symbol(): string::String {
        coin::symbol<BasicToken>()
    }

    #[view]
    public fun token_decimal(): u8 {
        coin::decimals<BasicToken>()
    }

}