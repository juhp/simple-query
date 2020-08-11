{-# LANGUAGE CPP #-}

module Network.HTTP.Query (
  Query,
  QueryItem,
  maybeKey,
  makeKey,
  makeItem,
  (+/+),
  webAPIQuery,
  lookupKey,
  lookupKeyEither,
  lookupKey'
  ) where

import Control.Monad.IO.Class (MonadIO)
import Data.Aeson.Types
#if !MIN_VERSION_http_conduit(2,3,3)
import Data.ByteString (ByteString)
#endif
import qualified Data.ByteString.Char8 as B
import Data.Text (Text)
import Network.HTTP.Client.Conduit
import Network.HTTP.Simple
import Network.URI

#if !MIN_VERSION_http_conduit(2,3,1)
type Query = [(ByteString, Maybe ByteString)]
#endif
#if !MIN_VERSION_http_conduit(2,3,3)
type QueryItem = (ByteString, Maybe ByteString)
#endif

-- | Maybe create a query key
maybeKey :: String -> Maybe String -> Query
maybeKey _ Nothing = []
maybeKey k mval = [(B.pack k, fmap B.pack mval)]

-- | make a singleton key-value Query
makeKey :: String -> String -> Query
makeKey k val = [(B.pack k, Just (B.pack val))]

-- | make a key-value QueryItem
makeItem :: String -> String -> QueryItem
makeItem k val = (B.pack k, Just (B.pack val))

-- | Combine two path segments with a slash
infixr 5 +/+
(+/+) :: String -> String -> String
"" +/+ s = s
s +/+ "" = s
s +/+ t | last s == '/' = s ++ t
        | head t == '/' = s ++ t
s +/+ t = s ++ '/' : t

-- | low-level web api query
webAPIQuery :: (MonadIO m, FromJSON a) => String -> Query -> m a
webAPIQuery url params =
  case parseURI url of
    Nothing -> error $ "Cannot parse uri: " ++ url
    Just uri ->
      let req = setRequestQueryString params $ requestFromURI_ uri
      in getResponseBody <$> httpJSON req

-- | looks up key in object
lookupKey :: FromJSON a => Text -> Object -> Maybe a
lookupKey k = parseMaybe (.: k)

-- | like lookupKey but returns error message if not found
lookupKeyEither :: FromJSON a => Text -> Object -> Either String a
lookupKeyEither k = parseEither (.: k)

-- | like lookupKey but raises an error if no key found
lookupKey' :: FromJSON a => Text -> Object -> a
lookupKey' k =
  either error id . parseEither (.: k)
