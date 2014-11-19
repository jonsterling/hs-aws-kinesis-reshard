-- Copyright (c) 2013-2014 PivotCloud, Inc.
--
-- Main
--
-- Please feel free to contact us at licensing@pivotmail.com with any
-- contributions, additions, or other feedback; we would love to hear from
-- you.
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may
-- not use this file except in compliance with the License. You may obtain a
-- copy of the License at http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
-- WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
-- License for the specific language governing permissions and limitations
-- under the License.
--

{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax #-}

module Main where

import AWS
import AWS.CloudWatch
import Aws.Kinesis.Resharder.Options

import Control.Applicative
import Control.Applicative.Unicode
import Control.Exception.Lifted
import Control.Lens
import Control.Monad.Error.Class
import Control.Monad.Reader.Class
import Control.Monad.Trans
import Control.Monad.Trans.Control
import Control.Monad.Trans.Either
import Control.Monad.Trans.Reader (runReaderT)
import Control.Monad.Trans.Resource
import Control.Monad.Unicode
import qualified Data.Text.Encoding as T
import qualified Options.Applicative as OA
import Prelude.Unicode

type MonadResharder m
  = ( MonadError SomeException m
    , MonadReader Options m
    , MonadIO m
    , MonadBaseControl IO m
    , MonadResource m
    )

getCredential
  ∷ MonadResharder m
  ⇒ m Credential
getCredential =
  pure newCredential
    ⊛ view (oAccessKey ∘ to T.encodeUtf8)
    ⊛ view (oSecretAccessKey ∘ to T.encodeUtf8)

app
  ∷ MonadResharder m
  ⇒ m ()
app = do
  cred ← getCredential
  res ← runCloudWatch cred $ do
    setRegion =≪ lift (view oRegion)
    listMetrics [] Nothing (Just "AWS/Kinesis") Nothing
  liftIO . print $ res

main ∷ IO ()
main =
  eitherT (fail ∘ show) return ∘ runResourceT $
    liftIO (OA.execParser parserInfo)
      ≫= runReaderT app

