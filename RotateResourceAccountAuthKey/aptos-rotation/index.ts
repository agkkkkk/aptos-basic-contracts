import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  MaybeHexString,
  Network,
  Provider,
  TxnBuilderTypes,
} from "aptos";
import * as dotenv from "dotenv";

dotenv.config();

const provider = new Provider(Network.DEVNET);
const client = new AptosClient(provider.aptosClient.nodeUrl);

const ACCOUNT1_PRIVATE_KEY: MaybeHexString = process.env.ACCOUNT1_PRIVATE_KEY!;
const ACCOUNT2_PRIVATE_KEY: MaybeHexString = process.env.ACCOUNT2_PRIVATE_KEY!;
const ACCOUNT3_PRIVATE_KEY: MaybeHexString = process.env.ACCOUNT3_PRIVATE_KEY!;

const hexString: Uint8Array =
  HexString.ensure(ACCOUNT1_PRIVATE_KEY).toUint8Array();
const hexString2: Uint8Array =
  HexString.ensure(ACCOUNT2_PRIVATE_KEY).toUint8Array();
const hexString3: Uint8Array =
  HexString.ensure(ACCOUNT2_PRIVATE_KEY).toUint8Array();

const sender = new AptosAccount(
  hexString,
  "0xf63c200b4f2ecd34d20231290ca8a927fe04e7b84a254985c22482c653a8af0b" // resource_account_address, fund resource account address for tx fee.
);

const account = new AptosAccount(hexString);

const receiver = new AptosAccount(hexString3);

const rotate_sender = new AptosAccount(
  hexString2,
  "0x92f124c07912d7f502f56fdbda864b9cdad6432c1a989476d95f38feb0e95dd2" // [RESOURCE ACCOUNT ADDRESS]
);

class SignerCapabilityOfferProofChallengeV2 {
  public readonly moduleAddress: TxnBuilderTypes.AccountAddress =
    TxnBuilderTypes.AccountAddress.CORE_CODE_ADDRESS;
  public readonly moduleName: string = "account";
  public readonly structName: string = "SignerCapabilityOfferProofChallengeV2";
  public readonly functionName: string = "offer_signer_capability";

  constructor(
    public readonly sequenceNumber: number,
    public readonly sourceAddress: TxnBuilderTypes.AccountAddress,
    public readonly recipientAddress: TxnBuilderTypes.AccountAddress
  ) {}

  serialize(serializer: BCS.Serializer): void {
    this.moduleAddress.serialize(serializer);
    serializer.serializeStr(this.moduleName);
    serializer.serializeStr(this.structName);
    serializer.serializeU64(this.sequenceNumber);
    this.sourceAddress.serialize(serializer);
    this.recipientAddress.serialize(serializer);
  }
}

class RotationCapabilityOfferProofChallengeV2 {
  public readonly moduleAddress: TxnBuilderTypes.AccountAddress =
    TxnBuilderTypes.AccountAddress.CORE_CODE_ADDRESS;
  public readonly moduleName: string = "account";
  public readonly structName: string =
    "RotationCapabilityOfferProofChallengeV2";
  public readonly functionName: string = "offer_rotation_capability";

  constructor(
    public readonly chainId: number,
    public readonly sequenceNumber: number,
    public readonly sourceAddress: TxnBuilderTypes.AccountAddress,
    public readonly recipientAddress: TxnBuilderTypes.AccountAddress
  ) {}

  serialize(serializer: BCS.Serializer): void {
    this.moduleAddress.serialize(serializer);
    serializer.serializeStr(this.moduleName);
    serializer.serializeStr(this.structName);
    serializer.serializeU8(this.chainId);
    serializer.serializeU64(this.sequenceNumber);
    this.sourceAddress.serialize(serializer);
    this.recipientAddress.serialize(serializer);
  }
}

const rotationProofChallenge = async () => {
  const proofChallenge = new RotationCapabilityOfferProofChallengeV2(
    await client.getChainId(),
    Number((await client.getAccount(rotate_sender.address())).sequence_number),
    TxnBuilderTypes.AccountAddress.fromHex(rotate_sender.address()),
    TxnBuilderTypes.AccountAddress.fromHex(account.address())
  );

  return proofChallenge;
};

const signerCapProofChallenge = async () => {
  const proofChallenge = new SignerCapabilityOfferProofChallengeV2(
    Number((await client.getAccount(sender.address())).sequence_number),
    TxnBuilderTypes.AccountAddress.fromHex(sender.address()),
    TxnBuilderTypes.AccountAddress.fromHex(account.address())
  );

  return proofChallenge;
};

const transaction = async (sender: AptosAccount, payload: any) => {
  const txn = await client.generateTransaction(sender.address(), payload);

  const signTx = await client.signTransaction(sender, txn);

  try {
    const tx = await client.submitTransaction(signTx);
    console.log(tx);
  } catch {
    console.log("error");
  }
};

const offerSignerCap = async () => {
  const signerProofChallenge = await signerCapProofChallenge();

  const signerStruct = BCS.bcsToBytes(signerProofChallenge);
  // console.log(signerStruct);
  // const signerCapSignedMessage = sender.signBuffer(signerStruct);

  const message = Buffer.from(signerStruct).toString("hex");
  const signerCapSignedMessage = sender.signHexString(message);

  console.log(
    "SignerCapabilityOfferProofChallengeV2 signature: ",
    signerCapSignedMessage
  );

  const offer_signer_cap_payload = {
    type: "entry_function_payload",
    function:
      "0x679f214e1a1e0b4341f55990c0ff2a514a63cf5a9a5b76c66ff6ac195f0fa220::rotate::offer_signer_cap",
    type_arguments: [],
    arguments: [account.address(), signerCapSignedMessage, sender.pubKey()],
  };

  transaction(sender, offer_signer_cap_payload);
};

const rotationCap = async () => {
  const rotateProofChallenge = await rotationProofChallenge();

  const rotationStruct = BCS.bcsToBytes(rotateProofChallenge);
  // console.log(rotationStruct);
  // const rotationCapSignedMessage = rotate_sender.signBuffer(rotationStruct);

  const message = Buffer.from(rotationStruct).toString("hex");
  const rotationCapSignedMessage = rotate_sender.signHexString(message);

  console.log(
    "RotationCapabilityOfferProofChallengeV2 signature: ",
    rotationCapSignedMessage
  );

  const rotation_cap_payload = {
    type: "entry_function_payload",
    function:
      "0x679f214e1a1e0b4341f55990c0ff2a514a63cf5a9a5b76c66ff6ac195f0fa220::rotate::offer_rotation_cap",
    type_arguments: [],
    arguments: [
      account.address(),
      rotationCapSignedMessage,
      rotate_sender.pubKey(),
    ],
  };

  transaction(rotate_sender, rotation_cap_payload);
};

const retrieveSignerCap = async () => {
  const retrieve_signer_cap_payload = {
    type: "entry_function_payload",
    function:
      "0x679f214e1a1e0b4341f55990c0ff2a514a63cf5a9a5b76c66ff6ac195f0fa220::rotate::retrive_signer_cap",
    type_arguments: [],
    arguments: [],
  };

  transaction(account, retrieve_signer_cap_payload);
};

(async () => {
  await offerSignerCap();
  await rotationCap();
  await retrieveSignerCap();
})();
