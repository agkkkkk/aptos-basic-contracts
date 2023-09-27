module voting_addr::Voting {

    use std::signer;
    use std::vector;
    use std::simple_map::{Self, SimpleMap};

    const E_NOT_OWNER: u64 = 0;
    const E_IS_NOT_INITIALIZED: u64 = 1;
    const E_DOES_NOT_CONTAIN_KEY: u64 = 2;
    const E_IS_INITIALIZED: u64 = 3;
    const E_IS_INITIALIZED_WITH_CANDIDATE: u64 = 4;
    const E_WINNER_DECLARED: u64 = 5;
    const E_HAS_VOTED: u64 = 6;

    struct Candidate has key {
        candidate_list: SimpleMap<address, u64>,
        candidate: vector<address>,
        winner: address
    }

    struct VoterList has key {
        voter: SimpleMap<address, u64>,
    }

    public fun assert_is_owner(account_addr: address) {
        assert!(account_addr == @voting_addr, 0);
    }

    public fun assert_is_initialized(account_addr: address) {
        assert!(exists<Candidate>(account_addr), 1);
        assert!(exists<VoterList>(account_addr), 1);
    }

    public fun assert_uninitialized(account_addr: address) {
        assert!(!exists<Candidate>(account_addr), 1);
        assert!(!exists<VoterList>(account_addr), 1);
    }

    public fun assert_contains_key(map: &SimpleMap<address, u64>, account_addr: &address) {
        assert!(simple_map::contains_key(map, account_addr), 2);
    }

    public fun assert_does_not_contains_key(map: &SimpleMap<address, u64>, account_addr: &address) {
        assert!(!simple_map::contains_key(map, account_addr), 4);
    }
    
    public entry fun initialize_with_candidate(account: &signer, candidate_addr: address) acquires Candidate {
        let signer_address = signer::address_of(account);

        assert_is_owner(signer_address);
        assert_uninitialized(signer_address);

        let candidate_store = Candidate {
            candidate_list: simple_map::create(),
            candidate: vector::empty<address>(),
            winner: @0x0
        };

        move_to(account, candidate_store);

        let voter_store = VoterList {
            voter: simple_map::create()
        };

        move_to(account, voter_store);

        let candidate_store = borrow_global_mut<Candidate>(signer_address);
        simple_map::add(&mut candidate_store.candidate_list, candidate_addr, 0);
        vector::push_back(&mut candidate_store.candidate, candidate_addr);
    }

    public entry fun add_candidate(account: &signer, candidate_addr: address) acquires Candidate {
        let signer_address = signer::address_of(account);

        assert_is_owner(signer_address);
        assert_is_initialized(signer_address);

        let candidate_store = borrow_global_mut<Candidate>(signer_address);
        
        assert!(candidate_store.winner == @0x0, 5);
        assert_does_not_contains_key(&candidate_store.candidate_list, &candidate_addr);
        
        simple_map::add(&mut candidate_store.candidate_list, candidate_addr, 0);
        vector::push_back(&mut candidate_store.candidate, candidate_addr);
    }

    public entry fun vote(account: &signer, candidate_addr: address, store_addr: address) acquires Candidate, VoterList {
        let signer_address = signer::address_of(account);

        assert_is_initialized(store_addr);

        let candidate_store = borrow_global_mut<Candidate>(store_addr);
        let voter_store = borrow_global_mut<VoterList>(store_addr);

        assert!(candidate_store.winner == @0x0, 5);
        assert!(!simple_map::contains_key(&voter_store.voter, &signer_address), 6);
        assert_contains_key(&candidate_store.candidate_list, &candidate_addr);

        let votes = simple_map::borrow_mut(&mut candidate_store.candidate_list, &candidate_addr);
        *votes = *votes + 1;
        simple_map::add(&mut voter_store.voter, signer_address, 1);
    }

    public entry fun declare_winner(account: &signer) acquires Candidate {
        let signer_address = signer::address_of(account);

        assert_is_owner(signer_address);
        assert_is_initialized(signer_address);

        let candidate_store = borrow_global_mut<Candidate>(signer_address);
        assert!(candidate_store.winner == @0x0, 5);

        let candidates = vector::length(&candidate_store.candidate);

        let i = 0;
        let winner_address: address = @0x0;
        let max_votes: u64 = 0;

        while(i < candidates) {
            let candidate = *vector::borrow(&candidate_store.candidate, (i as u64));
            let votes = simple_map::borrow(&candidate_store.candidate_list, &candidate);

            if (max_votes < *votes) {
                max_votes = *votes;
                winner_address = candidate;
            };

            i = i + 1;
        };

        candidate_store.winner = winner_address;
    }

    #[view]
    public fun get_candidate_list(store_account: address): vector<address> acquires Candidate {
        borrow_global<Candidate>(store_account).candidate
    }

    #[view]
    public fun get_winner(store_account: address): address acquires Candidate {
        borrow_global<Candidate>(store_account).winner
    }

    #[view]
    public fun get_candidates_vote_count(store_account: address): SimpleMap<address,u64> acquires Candidate {
        borrow_global<Candidate>(store_account).candidate_list
    }
}