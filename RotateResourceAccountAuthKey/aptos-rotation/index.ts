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

const hexString: Uint8Array =
  HexString.ensure(ACCOUNT1_PRIVATE_KEY).toUint8Array();
const hexString2: Uint8Array =
  HexString.ensure(ACCOUNT2_PRIVATE_KEY).toUint8Array();

const sender = new AptosAccount(
  // HexString.ensure(
  //   "0x85d044a5871b27208ea39ee519fc7393dbfd07bbcafa46e1bbde2ee5f290de23"
  // ).toUint8Array(),
  hexString
);
console.log(sender);
console.log(
  "publickey ",
  Buffer.from(sender.signingKey.publicKey).toString("hex")
);

const receiver = new AptosAccount(hexString2);

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
    Number((await client.getAccount(sender.address())).sequence_number),
    TxnBuilderTypes.AccountAddress.fromHex(sender.address()),
    TxnBuilderTypes.AccountAddress.fromHex(receiver.address())
  );

  return proofChallenge;
};

const signerCapProofChallenge = async () => {
  const proofChallenge = new SignerCapabilityOfferProofChallengeV2(
    Number((await client.getAccount(sender.address())).sequence_number),
    TxnBuilderTypes.AccountAddress.fromHex(sender.address()),
    TxnBuilderTypes.AccountAddress.fromHex(sender.address())
  );

  return proofChallenge;
};

const signStructAndSubmitTransaction = async (
  provider: Provider,
  signer: AptosAccount,
  struct:
    | SignerCapabilityOfferProofChallengeV2
    | RotationCapabilityOfferProofChallengeV2,
  accountScheme: number = 0
): Promise<any> => {
  const bcsStruct = BCS.bcsToBytes(struct);
  const signedMessage = signer.signBuffer(bcsStruct);

  const payload = new TxnBuilderTypes.TransactionPayloadEntryFunction(
    TxnBuilderTypes.EntryFunction.natural(
      `${struct.moduleAddress.toHexString()}::${struct.moduleName}`,
      struct.functionName,
      [],
      [
        BCS.bcsSerializeBytes(signedMessage.toUint8Array()),
        BCS.bcsSerializeU8(accountScheme),
        BCS.bcsSerializeBytes(signer.pubKey().toUint8Array()),
        BCS.bcsToBytes(struct.recipientAddress),
      ]
    )
  );
  const txnResponse = await provider.generateSignSubmitWaitForTransaction(
    signer,
    payload
  );
  return txnResponse;
};

(async () => {
  const signerProofChallenge = await signerCapProofChallenge();

  const rotateProofChallenge = await rotationProofChallenge();

  const signerStruct = BCS.bcsToBytes(signerProofChallenge);
  const signerCapSignedMessage = sender.signBuffer(signerStruct);

  console.log(
    "SignerCapabilityOfferProofChallengeV2 signature: ",
    signerCapSignedMessage
  );

  const rotationStruct = BCS.bcsToBytes(rotateProofChallenge);
  const rotateSignedMessage = sender.signBuffer(rotationStruct);

  console.log(
    "RotationCapabilityOfferProofChallengeV2 signature: ",
    rotateSignedMessage
  );

  console.log(
    await signStructAndSubmitTransaction(
      provider,
      sender,
      signerProofChallenge,
      0
    )
  );
})();
