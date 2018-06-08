module Test.Pos.Core.Gen
       (
        -- Pos.Core.Block Generators
          genBlockBodyAttributes
        , genBlockHeader
        , genBlockHeaderAttributes
        , genGenesisHash
        , genGenesisBlockHeader
        , genMainBlockHeader
        , genMainBody
        , genMainExtraBodyData
        , genMainExtraHeaderData
        , genMainProof
        , genMainToSign

        -- Pos.Core.Common Generators
        , genAddrAttributes
        , genAddress
        , genAddrType
        , genAddrSpendingData
        , genAddrStakeDistribution
        , genBlockCount
        , genChainDifficulty
        , genCoeff
        , genCoin
        , genCoinPortion
        , genScript
        , genScriptVersion
        , genSlotLeaders
        , genStakeholderId
        , genTxFeePolicy
        , genTxSizeLinear

        -- Pos.Core.Delegation Generators
        , genDlgPayload
        , genHeavyDlgIndex
        , genProxySKBlockInfo
        , genProxySKHeavy

        -- Pos.Core.Slotting Generators
        , genEpochIndex
        , genFlatSlotId
        , genLocalSlotIndex
        , genSlotId

        -- Pos.Core.Ssc Generators
        , genCommitment
        , genCommitmentsMap
        , genCommitmentSignature
        , genOpening
        , genSscPayload
        , genSscProof
        , genSignedCommitment
        , genVssCertificate
        , genVssCertificatesMap

        -- Pos.Core.Txp Generators
        , genPkWitness
        , genRedeemWitness
        , genScriptWitness
        , genTx
        , genTxAttributes
        , genTxHash
        , genTxId
        , genTxIn
        , genTxInList
        , genTxInWitness
        , genTxOut
        , genTxOutList
        , genTxPayload
        , genTxProof
        , genTxSig
        , genTxSigData
        , genTxWitness
        , genUnknownWitnessType

        -- Pos.Core.Update Generators
        , genBlockVersion
        , genBlockVersionModifier
        , genHashRaw
        , genSoftforkRule
        , genSoftwareVersion
        , genSystemTag
        , genUpAttributes
        , genUpdateData
        , genUpdatePayload
        , genUpdateProof
        , genUpdateProposal
        , genUpdateProposalToSign
        , genUpdateVote
        , genUpId
        , genUpsData

        -- Pos.Merkle Generators
        , genMerkleTreeTx
        , genMerkleRootTx
       ) where

import           Universum

import           Data.Coerce (coerce)
import           Data.Fixed (Fixed (..))
import qualified Data.HashMap.Strict as HM
import           Data.List.NonEmpty (fromList)
import           Data.Maybe
import           Data.Time.Units (fromMicroseconds, Millisecond)
import           Data.Vector (singleton)
import           Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import           Pos.Binary.Class (asBinary, Raw (..))
import           Pos.Block.Base (mkMainHeader, mkGenesisHeader)
import           Pos.Core.Block (BlockBodyAttributes, BlockHeader (..), BlockHeaderAttributes,
                                 GenesisBlockHeader, GenesisBody (..), MainBlockHeader,
                                 MainBody (..), MainExtraBodyData (..), MainExtraHeaderData (..),
                                 MainProof (..), MainToSign (..))
import           Pos.Core.Common (Address (..), AddrAttributes (..),
                                  AddrSpendingData (..), AddrStakeDistribution (..),
                                  AddrType (..), BlockCount (..), ChainDifficulty (..),
                                  Coeff (..), Coin (..),CoinPortion (..), makeAddress,
                                  Script (..), ScriptVersion, SlotLeaders, StakeholderId,
                                  TxFeePolicy (..), TxSizeLinear (..))
import           Pos.Core.Configuration (GenesisHash (..))
import           Pos.Core.Delegation (HeavyDlgIndex (..), ProxySKHeavy)
import           Pos.Core.Slotting (EpochIndex (..), FlatSlotId,
                                    LocalSlotIndex (..), SlotId (..))
import           Pos.Core.Ssc (Commitment, CommitmentSignature, CommitmentsMap,
                               mkCommitmentsMap, mkSscProof, mkVssCertificate,
                               mkVssCertificatesMap, Opening, SignedCommitment,
                               SscPayload (..), SscProof, VssCertificate (..),
                               VssCertificatesMap (..))
import           Pos.Core.Txp (TxAttributes, Tx (..), TxId, TxIn (..),
                               TxInWitness (..), TxOut (..), TxPayload (..),
                               TxProof (..), TxSig, TxSigData (..), TxWitness)
import           Pos.Core.Update (ApplicationName (..), BlockVersion (..),
                                  BlockVersionModifier (..), SoftforkRule(..),
                                  SoftwareVersion (..), SystemTag (..), UpAttributes,
                                  UpdateData (..), UpdatePayload (..), UpdateProof,
                                  UpdateProposal (..), UpdateProposalToSign  (..),
                                  UpdateVote (..), UpId)
import           Pos.Crypto (deterministic, Hash, hash, safeCreatePsk, sign)
import           Pos.Data.Attributes (mkAttributes)
import           Pos.Delegation.Types (DlgPayload (..), ProxySKBlockInfo)
import           Pos.Merkle (mkMerkleTree, mtRoot, MerkleRoot(..), MerkleTree (..))
import           Pos.Ssc.Base (genCommitmentAndOpening)
import           Test.Pos.Crypto.Gen (genAbstractHash, genHDAddressPayload,
                                      genProtocolMagic, genPublicKey,
                                      genRedeemPublicKey, genRedeemSignature,
                                      genSafeSigner, genSecretKey,
                                      genSignature, genSignTag,
                                      genVssPublicKey)
import           Serokell.Data.Memory.Units (Byte)


----------------------------------------------------------------------------
-- Pos.Core.Block Generators
----------------------------------------------------------------------------

genBlockBodyAttributes :: Gen BlockBodyAttributes
genBlockBodyAttributes = pure $ mkAttributes ()

genBlockHeader :: Gen BlockHeader
genBlockHeader =
    Gen.choice [ BlockHeaderGenesis <$> genGenesisBlockHeader
               , BlockHeaderMain <$> genMainBlockHeader
               ]

genBlockHeaderAttributes :: Gen BlockHeaderAttributes
genBlockHeaderAttributes = pure $ mkAttributes ()

genGenesisHash :: Gen GenesisHash
genGenesisHash = do
  sampleText <- Gen.text Range.constantBounded Gen.alphaNum
  pure $ GenesisHash (coerce (hash sampleText :: Hash Text))

genGenesisBlockHeader :: Gen GenesisBlockHeader
genGenesisBlockHeader =
    mkGenesisHeader
        <$> genProtocolMagic
        <*> Gen.choice gens
        <*> genEpochIndex
        <*> (GenesisBody <$> genSlotLeaders)
  where
    gens = [ Left <$> genGenesisHash
           , Right <$> genBlockHeader
           ]

genMainBody :: Gen MainBody
genMainBody =
    MainBody
        <$> genTxPayload
        <*> genSscPayload
        <*> genDlgPayload
        <*> genUpdatePayload

genMainBlockHeader :: Gen MainBlockHeader
genMainBlockHeader =
    mkMainHeader
        <$> genProtocolMagic
        <*> (Left <$> genGenesisHash)
        <*> genSlotId
        <*> genSecretKey
        <*> genProxySKBlockInfo
        <*> genMainBody
        <*> genMainExtraHeaderData

genMainExtraBodyData :: Gen MainExtraBodyData
genMainExtraBodyData = MainExtraBodyData <$> genBlockBodyAttributes

genMainExtraHeaderData :: Gen MainExtraHeaderData
genMainExtraHeaderData =
    MainExtraHeaderData
        <$> genBlockVersion
        <*> genSoftwareVersion
        <*> genBlockHeaderAttributes
        <*> genAbstractHash genMainExtraBodyData

genMainProof :: Gen MainProof
genMainProof =
    MainProof
        <$> genTxProof
        <*> genSscProof
        <*> genAbstractHash genDlgPayload
        <*> genUpdateProof

genMainToSign :: Gen MainToSign
genMainToSign =
    MainToSign
        <$> genAbstractHash genBlockHeader
        <*> genMainProof
        <*> genSlotId
        <*> genChainDifficulty
        <*> genMainExtraHeaderData

----------------------------------------------------------------------------
-- Pos.Core.Common Generators
----------------------------------------------------------------------------

genAddrAttributes :: Gen AddrAttributes
genAddrAttributes = AddrAttributes <$> hap <*> genAddrStakeDistribution
  where
    hap = Gen.maybe genHDAddressPayload

genAddress :: Gen Address
genAddress = makeAddress <$> genAddrSpendingData <*> genAddrAttributes

genAddrType :: Gen AddrType
genAddrType = Gen.choice [ pure ATPubKey
                         , pure ATScript
                         , pure ATRedeem
                         , ATUnknown <$> Gen.word8 Range.constantBounded
                         ]

genAddrSpendingData :: Gen AddrSpendingData
genAddrSpendingData = Gen.choice gens
  where
    gens = [ PubKeyASD <$> genPublicKey
           , ScriptASD <$> genScript
           , RedeemASD <$> genRedeemPublicKey
           , UnknownASD <$> Gen.word8 Range.constantBounded <*> gen32Bytes
           ]

genAddrStakeDistribution :: Gen AddrStakeDistribution
genAddrStakeDistribution = Gen.choice gens
  where
    gens = [ pure BootstrapEraDistr
           , SingleKeyDistr <$> genStakeholderId
           , UnsafeMultiKeyDistr <$> genMap
           ]
    genMap = Gen.map Range.constantBounded genPair
    genPair = do
      si <- genStakeholderId
      cp <- genCoinPortion
      pure (si, cp)

genBlockCount :: Gen BlockCount
genBlockCount = BlockCount <$> Gen.word64 Range.constantBounded

genChainDifficulty :: Gen ChainDifficulty
genChainDifficulty = ChainDifficulty <$> genBlockCount

genCoeff :: Gen Coeff
genCoeff = do
    integer <- Gen.integral (Range.constant 0 10)
    pure $ Coeff (MkFixed integer)

genCoin :: Gen Coin
genCoin = Coin <$> Gen.word64 Range.constantBounded

genCoinPortion :: Gen CoinPortion
genCoinPortion = CoinPortion <$> Gen.word64 Range.constantBounded

genScript :: Gen Script
genScript = Script <$> genScriptVersion <*> gen32Bytes

genScriptVersion :: Gen ScriptVersion
genScriptVersion = Gen.word16 Range.constantBounded

genSlotLeaders :: Gen SlotLeaders
genSlotLeaders = do
    stakeHolderList <- Gen.list (Range.constant 0 10) genStakeholderId
    pure $ fromJust $ nonEmpty stakeHolderList

genStakeholderId :: Gen StakeholderId
genStakeholderId = genAbstractHash genPublicKey

genTxFeePolicy :: Gen TxFeePolicy
genTxFeePolicy =
    Gen.choice [ TxFeePolicyTxSizeLinear <$> genTxSizeLinear
               , TxFeePolicyUnknown <$> genWord8 <*> gen32Bytes
               ]

genTxSizeLinear :: Gen TxSizeLinear
genTxSizeLinear = TxSizeLinear <$> genCoeff <*> genCoeff
----------------------------------------------------------------------------
-- Pos.Core.Delegation Generators
----------------------------------------------------------------------------

genHeavyDlgIndex :: Gen HeavyDlgIndex
genHeavyDlgIndex = HeavyDlgIndex <$> genEpochIndex

genDlgPayload :: Gen DlgPayload
genDlgPayload =
    UnsafeDlgPayload <$> Gen.list (Range.constant 0 10) genProxySKHeavy

genProxySKBlockInfo :: Gen ProxySKBlockInfo
genProxySKBlockInfo = do
    pSKHeavy <- genProxySKHeavy
    pubKey <- genPublicKey
    pure $ Just (pSKHeavy,pubKey)

genProxySKHeavy :: Gen ProxySKHeavy
genProxySKHeavy =
    safeCreatePsk
        <$> genProtocolMagic
        <*> genSafeSigner
        <*> genPublicKey
        <*> genHeavyDlgIndex

----------------------------------------------------------------------------
-- Pos.Core.Slotting Generators
----------------------------------------------------------------------------

genEpochIndex :: Gen EpochIndex
genEpochIndex = EpochIndex <$> Gen.word64 Range.constantBounded

genFlatSlotId :: Gen FlatSlotId
genFlatSlotId = Gen.word64 Range.constantBounded

genLocalSlotIndex :: Gen LocalSlotIndex
genLocalSlotIndex = UnsafeLocalSlotIndex <$> Gen.word16 (Range.constant 0 21599)

genSlotId :: Gen SlotId
genSlotId = SlotId <$> genEpochIndex <*> genLocalSlotIndex

----------------------------------------------------------------------------
-- Pos.Core.Ssc Generators
----------------------------------------------------------------------------

data CommitmentOpening = CommitmentOpening
    { unCommitment :: !Commitment
    , unOpening :: !Opening
    }

genCommitment :: Gen Commitment
genCommitment = unCommitment <$> genCommitmentOpening

genCommitmentOpening :: Gen CommitmentOpening
genCommitmentOpening = do
    let numKeys = 128 :: Int
    parties <-
        Gen.integral (Range.constant 4 (fromIntegral numKeys)) :: Gen Integer
    threshold <- Gen.integral (Range.constant 2 (parties - 2)) :: Gen Integer
    vssKeys <- replicateM numKeys genVssPublicKey
    pure
        $ uncurry CommitmentOpening
        $ deterministic "commitmentOpening"
        $ genCommitmentAndOpening threshold (fromList vssKeys)

genCommitmentSignature :: Gen CommitmentSignature
genCommitmentSignature = genSignature $ (,) <$> genEpochIndex <*> genCommitment

genCommitmentsMap :: Gen CommitmentsMap
genCommitmentsMap = mkCommitmentsMap <$> Gen.list range genSignedCommitment
  where
    range = Range.constant 1 100

genOpening :: Gen Opening
genOpening = unOpening <$> genCommitmentOpening

genSignedCommitment :: Gen SignedCommitment
genSignedCommitment =
    (,,) <$> genPublicKey <*> genCommitment <*> genCommitmentSignature

-- `SscPayload` gen needs two more constructors to be complete.
-- Generators from `crypto` are needed for these constructors.

genSscPayload :: Gen SscPayload
genSscPayload =
    Gen.choice
        [ CertificatesPayload <$> genVssCertificatesMap
        , CommitmentsPayload <$> genCommitmentsMap <*> genVssCertificatesMap
        ]

genSscProof :: Gen SscProof
genSscProof = mkSscProof <$> genSscPayload

genVssCertificate :: Gen VssCertificate
genVssCertificate =
    mkVssCertificate
        <$> genProtocolMagic
        <*> genSecretKey
        <*> (asBinary <$> genVssPublicKey)
        <*> genEpochIndex

genVssCertificatesMap :: Gen VssCertificatesMap
genVssCertificatesMap =
    mkVssCertificatesMap <$> Gen.list (Range.constant 0 10) genVssCertificate

----------------------------------------------------------------------------
-- Pos.Core.Txp Generators
----------------------------------------------------------------------------

genPkWitness :: Gen TxInWitness
genPkWitness = PkWitness <$> genPublicKey <*> genTxSig

genRedeemWitness :: Gen TxInWitness
genRedeemWitness =
    RedeemWitness <$> genRedeemPublicKey <*> genRedeemSignature genTxSigData

genScriptWitness :: Gen TxInWitness
genScriptWitness = ScriptWitness <$> genScript <*> genScript

genTx :: Gen Tx
genTx = UnsafeTx <$> genTxInList <*> genTxOutList <*> genTxAttributes

genTxAttributes :: Gen TxAttributes
genTxAttributes = pure $ mkAttributes ()

genTxHash :: Gen (Hash Tx)
genTxHash = hash <$> genTx

genTxIn :: Gen TxIn
genTxIn = Gen.choice gens
  where
    gens = [ TxInUtxo <$> genTxId <*> genWord32
           , TxInUnknown <$> genWord8 <*> gen32Bytes
           ]

genTxInList :: Gen (NonEmpty TxIn)
genTxInList = Gen.nonEmpty (Range.constant 1 100) genTxIn

genTxOut :: Gen TxOut
genTxOut = TxOut <$> genAddress <*> genCoin

genTxOutList :: Gen (NonEmpty TxOut)
genTxOutList = Gen.nonEmpty (Range.constant 1 100) genTxOut

genTxId :: Gen TxId
genTxId = hash <$> genTx

genTxPayload :: Gen TxPayload
genTxPayload =
    UnsafeTxPayload
        <$> Gen.list (Range.constant 1 10) genTx
        <*> Gen.list (Range.constant 1 10) genTxWitness

genTxProof :: Gen TxProof
genTxProof =
    TxProof
        <$> genWord32
        <*> genMerkleRootTx
        <*> genAbstractHash (Gen.list (Range.constant 1 20) genTxWitness)

genTxSig :: Gen TxSig
genTxSig =
    sign <$> genProtocolMagic <*> genSignTag <*> genSecretKey <*> genTxSigData

genTxSigData :: Gen TxSigData
genTxSigData = TxSigData <$> genTxHash

genTxInWitness :: Gen TxInWitness
genTxInWitness = Gen.choice gens
  where
    gens = [ genPkWitness
           , genRedeemWitness
           , genScriptWitness
           , genUnknownWitnessType
           ]

genTxWitness :: Gen TxWitness
genTxWitness = singleton <$> genTxInWitness

genUnknownWitnessType :: Gen TxInWitness
genUnknownWitnessType =
    UnknownWitnessType <$> Gen.word8 Range.constantBounded <*> gen32Bytes

----------------------------------------------------------------------------
-- Pos.Core.Update Generators
----------------------------------------------------------------------------

genApplicationName :: Gen ApplicationName
genApplicationName =
    ApplicationName <$> Gen.text (Range.constant 0 10) Gen.alphaNum

genBlockVersion :: Gen BlockVersion
genBlockVersion =
    BlockVersion
        <$> Gen.word16 Range.constantBounded
        <*> Gen.word16 Range.constantBounded
        <*> Gen.word8 Range.constantBounded

genBlockVersionModifier :: Gen BlockVersionModifier
genBlockVersionModifier =
    BlockVersionModifier
        <$> Gen.maybe genScriptVersion
        <*> Gen.maybe genMillisecond
        <*> Gen.maybe genByte
        <*> Gen.maybe genByte
        <*> Gen.maybe genByte
        <*> Gen.maybe genByte
        <*> Gen.maybe genCoinPortion
        <*> Gen.maybe genCoinPortion
        <*> Gen.maybe genCoinPortion
        <*> Gen.maybe genCoinPortion
        <*> Gen.maybe genFlatSlotId
        <*> Gen.maybe genSoftforkRule
        <*> Gen.maybe genTxFeePolicy
        <*> Gen.maybe genEpochIndex


genHashRaw :: Gen (Hash Raw)
genHashRaw = genAbstractHash $ Raw <$> gen32Bytes

genSoftforkRule :: Gen SoftforkRule
genSoftforkRule =
    SoftforkRule <$> genCoinPortion <*> genCoinPortion <*> genCoinPortion

genSoftwareVersion :: Gen SoftwareVersion
genSoftwareVersion =
    SoftwareVersion
        <$> genApplicationName
        <*> Gen.word32 Range.constantBounded

genSystemTag :: Gen SystemTag
genSystemTag = SystemTag <$> Gen.text (Range.constant 0 10) Gen.alphaNum

genUpAttributes :: Gen UpAttributes
genUpAttributes = pure $ mkAttributes ()

genUpdateData :: Gen UpdateData
genUpdateData =
    UpdateData
        <$> genHashRaw
        <*> genHashRaw
        <*> genHashRaw
        <*> genHashRaw

genUpdatePayload :: Gen UpdatePayload
genUpdatePayload =
    UpdatePayload
        <$> Gen.maybe genUpdateProposal
        <*> Gen.list (Range.constant 0 10) genUpdateVote

genUpdateProof :: Gen UpdateProof
genUpdateProof = genAbstractHash genUpdatePayload

genUpdateProposal :: Gen UpdateProposal
genUpdateProposal =
    UnsafeUpdateProposal
        <$> genBlockVersion
        <*> genBlockVersionModifier
        <*> genSoftwareVersion
        <*> genUpsData
        <*> genUpAttributes
        <*> genPublicKey
        <*> genSignature genUpdateProposalToSign

genUpdateProposalToSign :: Gen UpdateProposalToSign
genUpdateProposalToSign =
    UpdateProposalToSign
        <$> genBlockVersion
        <*> genBlockVersionModifier
        <*> genSoftwareVersion
        <*> genUpsData
        <*> genUpAttributes

genUpId :: Gen UpId
genUpId = genAbstractHash genUpdateProposal

genUpsData :: Gen (HM.HashMap SystemTag UpdateData)
genUpsData = do
    hMapSize <- Gen.int (Range.constant 0 20)
    sysTagList <- Gen.list (Range.singleton hMapSize) genSystemTag
    upDataList <- Gen.list (Range.singleton hMapSize) genUpdateData
    pure $ HM.fromList $ zip sysTagList upDataList

genUpdateVote :: Gen UpdateVote
genUpdateVote =
    UnsafeUpdateVote
        <$> genPublicKey
        <*> genUpId
        <*> Gen.bool
        <*> genSignature ((,) <$> genUpId <*> Gen.bool)

----------------------------------------------------------------------------
-- Pos.Merkle Generators
----------------------------------------------------------------------------

genMerkleTreeTx :: Gen (MerkleTree Tx)
genMerkleTreeTx = mkMerkleTree <$> Gen.list (Range.constant 0 100) genTx

genMerkleRootTx :: Gen (MerkleRoot Tx)
genMerkleRootTx = mtRoot <$> genMerkleTreeTx

----------------------------------------------------------------------------
-- Helper Generators
----------------------------------------------------------------------------

genBytes :: Int -> Gen ByteString
genBytes n = Gen.bytes (Range.singleton n)

genByte :: Gen Byte
genByte = Gen.integral (Range.constant 0 10)

gen32Bytes :: Gen ByteString
gen32Bytes = genBytes 32

genMillisecond :: Gen Millisecond
genMillisecond = fromMicroseconds <$> Gen.integral (Range.constant 0 1000000)

genWord32 :: Gen Word32
genWord32 = Gen.word32 Range.constantBounded

genWord8 :: Gen Word8
genWord8 = Gen.word8 Range.constantBounded