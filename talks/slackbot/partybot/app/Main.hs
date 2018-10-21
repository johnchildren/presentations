{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Data.Text
import           Network.Linklater
import           Network.Wai.Handler.Warp (run)

main :: IO ()
main = do
  run port (slashSimple ourBot)
  where
    port = 4446

ourBot :: Command -> IO Text
ourBot cmd@(Command "party" user channel Nothing) = do
    let icon = EmojiIcon ":raised_hands:"
        myName = "partbot"
        message = [FormatString ":party_parrot:"]
    say (FormattedMessage icon myName channel message) config
    return "ok"
ourBot cmd@(Command "party" user channel (Just text)) = do
    let icon = EmojiIcon ":raised_hands:"
        myName = "partbot"
        message = [FormatString ":party_parrot:"]
    say (FormattedMessage icon myName channel message) config
    return "ok"
ourBot _ = return "not a party :("
