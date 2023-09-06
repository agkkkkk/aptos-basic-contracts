module native_token_transfer::transfer_coin {
    use std::aptos_account;

    public entry fun transfer_coin(account: &signer, to: address, amount: u64) {
        aptos_account::transfer(account, to, amount);
    }
}