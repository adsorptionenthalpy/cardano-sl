module Test.Pos.Core.Dummy
       ( dummyProtocolConstants
       ) where

import           Pos.Core.ProtocolConstants (ProtocolConstants (..))

dummyProtocolConstants :: ProtocolConstants
dummyProtocolConstants =
    ProtocolConstants {pcK = 10, pcVssMinTTL = 2, pcVssMaxTTL = 6}
