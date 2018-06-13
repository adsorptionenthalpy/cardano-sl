-- | Types related to Toss.

module Pos.Ssc.Toss.Types
       ( SscTag (..)
       , isGoodSlotForTag
       , isGoodSlotIdForTag

       , TossModifier (..)
       , tmCommitments
       , tmOpenings
       , tmShares
       , tmCertificates
       ) where

import           Control.Lens (makeLenses)
import qualified Data.Text.Buildable as Buildable
import           Universum

import           Pos.Core (BlockCount, LocalSlotIndex, SlotId, VssCertificatesMap)
import           Pos.Core.Ssc (CommitmentsMap, OpeningsMap, SharesMap)
import           Pos.Ssc.Base (isCommitmentId, isCommitmentIdx, isOpeningId, isOpeningIdx,
                               isSharesId, isSharesIdx)

-- | Tag corresponding to SSC data.
data SscTag
    = CommitmentMsg
    | OpeningMsg
    | SharesMsg
    | VssCertificateMsg
    deriving (Show, Eq, Generic)

instance Buildable SscTag where
    build CommitmentMsg     = "commitment"
    build OpeningMsg        = "opening"
    build SharesMsg         = "shares"
    build VssCertificateMsg = "VSS certificate"

isGoodSlotForTag :: BlockCount -> SscTag -> LocalSlotIndex -> Bool
isGoodSlotForTag k = \case
    CommitmentMsg     -> isCommitmentIdx k
    OpeningMsg        -> isOpeningIdx k
    SharesMsg         -> isSharesIdx k
    VssCertificateMsg -> const True

isGoodSlotIdForTag :: BlockCount -> SscTag -> SlotId -> Bool
isGoodSlotIdForTag k = \case
    CommitmentMsg     -> isCommitmentId k
    OpeningMsg        -> isOpeningId k
    SharesMsg         -> isSharesId k
    VssCertificateMsg -> const True

data TossModifier = TossModifier
    { _tmCommitments  :: !CommitmentsMap
    , _tmOpenings     :: !OpeningsMap
    , _tmShares       :: !SharesMap
    , _tmCertificates :: !VssCertificatesMap
    } deriving (Generic, Show, Eq)

makeLenses ''TossModifier

instance Monoid TossModifier where
    mempty = TossModifier mempty mempty mempty mempty
    mappend (TossModifier leftComms leftOpens leftShares leftCerts)
            (TossModifier rightComms rightOpens rightShares rightCerts) =
        TossModifier
        { _tmCommitments = rightComms <> leftComms
        , _tmOpenings = rightOpens <> leftOpens
        , _tmShares = rightShares <> leftShares
        , _tmCertificates = rightCerts <> leftCerts
        }

instance Semigroup TossModifier
