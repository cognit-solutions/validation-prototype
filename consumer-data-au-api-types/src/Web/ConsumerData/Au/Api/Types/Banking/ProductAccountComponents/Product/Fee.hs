{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE LambdaCase            #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE TypeOperators         #-}
module Web.ConsumerData.Au.Api.Types.Banking.ProductAccountComponents.Product.Fee
  ( module Web.ConsumerData.Au.Api.Types.Banking.ProductAccountComponents.Product.Fee
  ) where

import           Control.Monad.Except       (throwError)
import           Data.Functor.Contravariant (contramap, (>$<))
import           Data.Text                  (Text)
import           Text.URI                   (URI)
import           Waargonaut.Decode          (Decoder)
import qualified Waargonaut.Decode          as D
import qualified Waargonaut.Decode.Error    as D
import           Waargonaut.Encode          (Encoder)
import qualified Waargonaut.Encode          as E
import           Waargonaut.Generic         (JsonDecode (..), JsonEncode (..))
import           Waargonaut.Types.JObject   (MapLikeObj)
import           Waargonaut.Types.Json      (Json)

import           Waargonaut.Helpers         (atKeyOptional', maybeOrAbsentE)
import Web.ConsumerData.Au.Api.Types.Banking.ProductAccountComponents.AdditionalValue
    (additionalValueDecoder)
import Web.ConsumerData.Au.Api.Types.Banking.ProductAccountComponents.Product.Discount
    (ProductDiscounts, productDiscountsDecoder, productDiscountsEncoder)
import Web.ConsumerData.Au.Api.Types.Data.CommonFieldTypes
    (AmountString, CurrencyString, DurationString, RateString,
    amountStringDecoder, amountStringEncoder, currencyStringDecoder,
    currencyStringEncoder, durationStringDecoder, durationStringEncoder,
    rateStringDecoder, rateStringEncoder)
import Web.ConsumerData.Au.Api.Types.Response
    (uriDecoder, uriEncoder)
import Web.ConsumerData.Au.Api.Types.Tag
    (OB, tagOb)


newtype ProductFees =
  ProductFees { getProductFees :: [ProductFee] }
  deriving (Eq, Show)

productFeesDecoder :: Monad f => Decoder f ProductFees
productFeesDecoder = ProductFees <$> D.list productFeeDecoder

productFeesEncoder :: Applicative f => Encoder f ProductFees
productFeesEncoder = getProductFees >$< E.list productFeeEncoder

instance JsonDecode OB ProductFees where
  mkDecoder = tagOb productFeesDecoder

instance JsonEncode OB ProductFees where
  mkEncoder = tagOb productFeesEncoder



data ProductFee = ProductFee
  { _productFeeName              :: Text
  , _productFeeFeeType           :: ProductFeeType
  , _productFeeAmount            :: Maybe AmountString
  , _productFeeBalanceRate       :: Maybe RateString
  , _productFeeTransactionRate   :: Maybe RateString
  , _productFeeCurrency          :: Maybe CurrencyString
  , _productFeeAdditionalInfo    :: Maybe Text
  , _productFeeAdditionalInfoUri :: Maybe URI
  , _productFeeDiscounts         :: Maybe ProductDiscounts
  } deriving (Show, Eq)

productFeeDecoder :: Monad f => Decoder f ProductFee
productFeeDecoder =
  ProductFee
    <$> D.atKey "name" D.text
    <*> productFeeTypeDecoder
    <*> atKeyOptional' "amount" amountStringDecoder
    <*> atKeyOptional' "balanceRate" rateStringDecoder
    <*> atKeyOptional' "transactionRate" rateStringDecoder
    <*> atKeyOptional' "currency" currencyStringDecoder
    <*> atKeyOptional' "additionalInfo" D.text
    <*> atKeyOptional' "additionalInfoUri" uriDecoder
    <*> atKeyOptional' "discounts" productDiscountsDecoder

instance JsonDecode OB ProductFee where
  mkDecoder = tagOb productFeeDecoder

productFeeEncoder :: Applicative f => Encoder f ProductFee
productFeeEncoder = E.mapLikeObj $ \p ->
  E.atKey' "name" E.text (_productFeeName p) .
  productFeeTypeFields (_productFeeFeeType p) .
  maybeOrAbsentE "amount" amountStringEncoder (_productFeeAmount p) .
  maybeOrAbsentE "balanceRate" rateStringEncoder (_productFeeBalanceRate p) .
  maybeOrAbsentE "transactionRate" rateStringEncoder (_productFeeTransactionRate p) .
  maybeOrAbsentE "currency" currencyStringEncoder (_productFeeCurrency p) .
  maybeOrAbsentE "additionalInfo" E.text (_productFeeAdditionalInfo p) .
  maybeOrAbsentE "additionalInfoUri" uriEncoder (_productFeeAdditionalInfoUri p) .
  maybeOrAbsentE "discounts" productDiscountsEncoder (_productFeeDiscounts p)

instance JsonEncode OB ProductFee where
  mkEncoder = tagOb productFeeEncoder


data ProductFeeType =
    PFeePeriodicPeriodic DurationString
    -- ^ "PERIODIC" A periodic fee such as a monthly account servicing fee. Use of @additionalValue@ field: The period of charge. Formatted according to ISO 8601 Durations.
  | PFeePeriodicTransaction Text
    -- ^ "TRANSACTION" A fee for each transaction (above any free transactions in a period). Use of @additionalValue@ field: A description of the type of transaction (eg. Assisted Transaction, Teller Transaction, Cheque).
  | PFeePeriodicEstablishment
    -- ^ "ESTABLISHMENT" An establishment fee for the product.
  | PFeePeriodicExit
    -- ^ "EXIT" A fee for closing the product.
  | PFeePeriodicOverdraw
    -- ^ "OVERDRAW" A fee for overdrawing the account.
  | PFeePeriodicMinBalance DurationString
    -- ^ "MIN_BALANCE" A periodic fee for being below the minimum balance. Use of @additionalValue@ field: The period of charge. Formatted according to ISO 8601 Durations.
  | PFeePeriodicRedraw
    -- ^ "REDRAW" A fee for performing a redraw transaction.
  | PFeePeriodicChequeCash
    -- ^ "CHEQUE_CASH" A fee for cashing a cheque.
  | PFeePeriodicChequeStop
    -- ^ "CHEQUE_STOP" A fee for stopping a cheque.
  | PFeePeriodicChequeBook
    -- ^ "CHEQUE_BOOK" A fee for ordering a new cheque book.
  | PFeePeriodicCardReplace
    -- ^ "CARD_REPLACE" A fee for ordering a replacement card.
  | PFeePeriodicPaperStatement
    -- ^ "PAPER_STATEMENT" A fee for obtaining a paper statement.
  | PFeePeriodicOtherEvent Text
    -- ^ "OTHER_EVENT" A fee for another type of event not already specified in the list of valid values. Use of @additionalValue@ field: Text description of the event.
  deriving (Show, Eq)

productFeeTypeDecoder :: Monad f => Decoder f ProductFeeType
productFeeTypeDecoder = do
  feeType <- D.atKey "feeType" D.text
  additionalValue <- case feeType of
    "PERIODIC" -> PFeePeriodicPeriodic <$> (additionalValueDecoder durationStringDecoder)
    "TRANSACTION" -> PFeePeriodicTransaction <$> (additionalValueDecoder D.text)
    "ESTABLISHMENT" -> pure PFeePeriodicEstablishment
    "EXIT" -> pure PFeePeriodicExit
    "OVERDRAW" -> pure PFeePeriodicOverdraw
    "MIN_BALANCE" -> PFeePeriodicMinBalance <$> (additionalValueDecoder durationStringDecoder)
    "REDRAW" -> pure PFeePeriodicRedraw
    "CHEQUE_CASH" -> pure PFeePeriodicChequeCash
    "CHEQUE_STOP" -> pure PFeePeriodicChequeStop
    "CHEQUE_BOOK" -> pure PFeePeriodicChequeBook
    "CARD_REPLACE" -> pure PFeePeriodicCardReplace
    "PAPER_STATEMENT" -> pure PFeePeriodicPaperStatement
    "OTHER_EVENT" -> PFeePeriodicOtherEvent <$> (additionalValueDecoder D.text)
    _ -> throwError D.KeyDecodeFailed
  pure additionalValue

productFeeType'ToText :: ProductFeeType' -> Text
productFeeType'ToText = \case
  PFeePeriodicPeriodic' -> "PERIODIC"
  PFeePeriodicTransaction' -> "TRANSACTION"
  PFeePeriodicEstablishment' -> "ESTABLISHMENT"
  PFeePeriodicExit' -> "EXIT"
  PFeePeriodicOverdraw' -> "OVERDRAW"
  PFeePeriodicMinBalance' -> "MIN_BALANCE"
  PFeePeriodicRedraw' -> "REDRAW"
  PFeePeriodicChequeCash' -> "CHEQUE_CASH"
  PFeePeriodicChequeStop' -> "CHEQUE_STOP"
  PFeePeriodicChequeBook' -> "CHEQUE_BOOK"
  PFeePeriodicCardReplace' -> "CARD_REPLACE"
  PFeePeriodicPaperStatement' -> "PAPER_STATEMENT"
  PFeePeriodicOtherEvent' -> "OTHER_EVENT"

data ProductFeeType' =
    PFeePeriodicPeriodic'
  | PFeePeriodicTransaction'
  | PFeePeriodicEstablishment'
  | PFeePeriodicExit'
  | PFeePeriodicOverdraw'
  | PFeePeriodicMinBalance'
  | PFeePeriodicRedraw'
  | PFeePeriodicChequeCash'
  | PFeePeriodicChequeStop'
  | PFeePeriodicChequeBook'
  | PFeePeriodicCardReplace'
  | PFeePeriodicPaperStatement'
  | PFeePeriodicOtherEvent'
  deriving (Eq, Show)

productFeeType'Encoder :: Applicative f => Encoder f ProductFeeType'
productFeeType'Encoder = flip contramap E.text productFeeType'ToText

productFeeTypeToType' :: ProductFeeType -> ProductFeeType'
productFeeTypeToType' (PFeePeriodicPeriodic {}) = PFeePeriodicPeriodic'
productFeeTypeToType' (PFeePeriodicTransaction {}) = PFeePeriodicTransaction'
productFeeTypeToType' (PFeePeriodicEstablishment {}) = PFeePeriodicEstablishment'
productFeeTypeToType' (PFeePeriodicExit {}) = PFeePeriodicExit'
productFeeTypeToType' (PFeePeriodicOverdraw {}) = PFeePeriodicOverdraw'
productFeeTypeToType' (PFeePeriodicMinBalance {}) = PFeePeriodicMinBalance'
productFeeTypeToType' (PFeePeriodicRedraw {}) = PFeePeriodicRedraw'
productFeeTypeToType' (PFeePeriodicChequeCash {}) = PFeePeriodicChequeCash'
productFeeTypeToType' (PFeePeriodicChequeStop {}) = PFeePeriodicChequeStop'
productFeeTypeToType' (PFeePeriodicChequeBook {}) = PFeePeriodicChequeBook'
productFeeTypeToType' (PFeePeriodicCardReplace {}) = PFeePeriodicCardReplace'
productFeeTypeToType' (PFeePeriodicPaperStatement {}) = PFeePeriodicPaperStatement'
productFeeTypeToType' (PFeePeriodicOtherEvent {}) = PFeePeriodicOtherEvent'

productFeeTypeFields :: (Monoid ws, Semigroup ws) => ProductFeeType -> MapLikeObj ws Json -> MapLikeObj ws Json
productFeeTypeFields pc =
  case pc of
    PFeePeriodicPeriodic v ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc) .
      E.atKey' "additionalValue" durationStringEncoder v
    PFeePeriodicTransaction v ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc) .
      E.atKey' "additionalValue" E.text v
    PFeePeriodicEstablishment ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicExit ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicOverdraw ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicMinBalance v ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc) .
      E.atKey' "additionalValue" durationStringEncoder v
    PFeePeriodicRedraw ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicChequeCash ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicChequeStop ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicChequeBook ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicCardReplace ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicPaperStatement ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc)
    PFeePeriodicOtherEvent v ->
      E.atKey' "feeType" productFeeType'Encoder (productFeeTypeToType' pc) .
      E.atKey' "additionalValue" E.text v

instance JsonDecode OB ProductFeeType where
  mkDecoder = tagOb productFeeTypeDecoder
