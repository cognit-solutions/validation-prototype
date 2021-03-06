module Web.ConsumerData.Au.Api.Types.Banking.PayeesGens where

import           Control.Applicative (liftA2)
import           Control.Monad       (replicateM)
import           Country.Gens        (countryGen)
import           Data.Text           (Text)
import qualified Data.Text           as Text
import           Hedgehog
import qualified Hedgehog.Gen        as Gen
import qualified Hedgehog.Range      as Range

import Data.Text.Gens
import Web.ConsumerData.Au.Api.Types
import Web.ConsumerData.Au.Api.Types.Data.CommonFieldTypesGens (dateStringGen)

payeeGen :: Gen Payee
payeeGen = Payee
  <$> payeeIdGen
  <*> textGen
  <*> Gen.maybe textGen
  <*> payeeTypeGen
  <*> Gen.maybe dateStringGen

payeeIdGen :: Gen PayeeId
payeeIdGen = PayeeId <$> Gen.text (Range.linear 5 20) Gen.unicode

payeeTypeGen :: Gen PayeeType
payeeTypeGen = Gen.element [Domestic, International, Biller]

payeeDetailGen :: Gen PayeeDetail
payeeDetailGen = PayeeDetail <$> payeeGen <*> payeeTypeDataGen

payeeTypeDataGen :: Gen PayeeTypeData
payeeTypeDataGen = Gen.choice
  [ PTDDomestic <$> domesticPayeeGen
  , PTDInternational <$> internationalPayeeGen
  , PTDBiller <$> billerPayeeGen
  ]

domesticPayeeGen :: Gen DomesticPayee
domesticPayeeGen = Gen.choice
  [ DPAccount <$> domesticPayeeAccountGen
  , DPCard <$> domesticPayeeCardGen
  , DPPayeeId <$> domesticPayeePayIdGen
  ]

domesticPayeeAccountGen :: Gen DomesticPayeeAccount
domesticPayeeAccountGen =
  DomesticPayeeAccount <$> textGen <*> bsbGen <*> textGen

bsbGen :: Gen Text
bsbGen =
  let d3 = replicateM 3 Gen.digit
      (<<>>) = liftA2 (<>)
  in  Text.pack <$> (d3 <<>> pure "-" <<>> d3)

domesticPayeeCardGen :: Gen DomesticPayeeCard
domesticPayeeCardGen = DomesticPayeeCard <$> textGen

domesticPayeePayIdGen :: Gen DomesticPayeePayId
domesticPayeePayIdGen =
  DomesticPayeePayId <$> Gen.maybe textGen <*> textGen <*> domesticPayeePayIdTypeGen

domesticPayeePayIdTypeGen :: Gen DomesticPayeePayIdType
domesticPayeePayIdTypeGen = Gen.element [Email, Mobile, OrgNumber, OrgName]

internationalPayeeGen :: Gen InternationalPayee
internationalPayeeGen =
  InternationalPayee <$> beneficiaryDetailsGen <*> bankDetailsGen

beneficiaryDetailsGen :: Gen BeneficiaryDetails
beneficiaryDetailsGen = BeneficiaryDetails <$> Gen.maybe textGen <*> countryGen <*> Gen.maybe textGen

bankDetailsGen :: Gen BankDetails
bankDetailsGen =
  BankDetails <$> countryGen <*> textGen <*> Gen.maybe bankAddressGen <*>
  Gen.maybe textGen <*> Gen.maybe textGen <*> Gen.maybe textGen <*> Gen.maybe textGen
  <*> Gen.maybe textGen <*> Gen.maybe textGen

bankAddressGen :: Gen BankAddress
bankAddressGen = BankAddress <$> textGen <*> textGen

billerPayeeGen :: Gen BillerPayee
billerPayeeGen =
  let numText = Text.pack . show <$> Gen.int (Range.linear 0 maxBound)
  in  BillerPayee <$> numText <*> Gen.maybe numText <*> textGen
