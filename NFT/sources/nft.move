module nft::nft {
  use std::string::{Self, String};
  use std::vector;
  use std::option;
  use std::signer::{address_of};

  use aptos_token::token;
  use aptos_framework::account;

  struct NFT has key {
    signer_cap: account::SignerCapability,
    collection: String,
    total_minted: u64,
  }

  fun init_module(account: &signer) {
    let collection_name = string::utf8(b"NFT Collection");
    let description = string::utf8(b"NFT issued by ME");
    let collection_uri = string::utf8(b"https://img.freepik.com/free-vector/hand-drawn-nft-style-ape-illustration_23-2149622024.jpg");
    

    let maximum_supply = 10;
    let mutate_setting = vector<bool>[ false, false, false ];

    let (_,resource_signer_cap) = account::create_resource_account(account, b"nft");
    let resource_signer = account::create_signer_with_capability(&resource_signer_cap);
    
    token::create_collection(&resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

    move_to(account, NFT {
      signer_cap: resource_signer_cap,
      collection: collection_name,
      total_minted: 0,
    });
  }

  public entry fun mint_nft(receiver: &signer) acquires NFT {
    let nft = borrow_global_mut<NFT>(@nft);
    let nft_id = nft.total_minted + 1;
    nft.total_minted = nft_id;
    let resource_signer = account::create_signer_with_capability(&nft.signer_cap);
    let resource_account_address = address_of(&resource_signer);

    let token_name = string::utf8(b"NFT ");
    string::append(&mut token_name, string::utf8(b"#"));
    string::append(&mut token_name, num_str(nft_id));
    let token_description = string::utf8(b"");
    let token_uri = string::utf8(b"https://ipfs.io/ipfs/QmNRU6xPgDQqyCcoUBg2xDe4C4f8XTz9kckE3DUx4ZgeDt?filename=coin.jpg");

    let token_data_id = token::create_tokendata(
      &resource_signer,
      nft.collection,
      token_name,
      token_description,
      1,
      token_uri,
      resource_account_address,
      1,
      0,
      token::create_token_mutability_config(
        &vector<bool>[ false, false, false, false, true ]
      ),
      vector::empty<String>(),
      vector::empty<vector<u8>>(),
      vector::empty<String>(),
    );

    let token_id = token::mint_token(&resource_signer, token_data_id, 1);
    token::direct_transfer(&resource_signer, receiver, token_id, 1);
  }

  #[view]
  public fun get_collection_supply(creator: address, collection: string::String): option::Option<u64> {
    token::get_collection_supply(creator, collection)
  }
  #[view]
  public fun collection_exist(creator: address, collection: string::String): bool {
    token::check_collection_exists(creator, collection)
  }

  fun num_str(num: u64): string::String {
    let vec = vector::empty();

    while (num/10 > 0) {
      let temp = num % 10;
      num = num / 10;

      vector::push_back(&mut vec, (temp+48 as u8));
    };

    vector::push_back(&mut vec, (num+48 as u8));
    vector::reverse(&mut vec);

    string::utf8(vec)
  }
}