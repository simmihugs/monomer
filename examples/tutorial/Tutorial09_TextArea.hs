{-|
Module      : Tutorial09_TextArea
Copyright   : (c) 2018 Francisco Vallarino
License     : BSD-3-Clause (see the LICENSE file)
Maintainer  : fjvallarino@gmail.com
Stability   : experimental
Portability : non-portable

Main module for the 'Tutorial 09 - TextArea with Linenumbers' tutorial.
-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Tutorial09_TextArea where

import Control.Lens
import Data.Text (Text)
import Monomer

import qualified Monomer.Lens as L

data AppModel = AppModel {
  _sampleText :: Text
} deriving (Eq, Show)

data AppEvent
  = AppInit
  deriving (Eq, Show)

makeLenses 'AppModel

buildUI
  :: WidgetEnv AppModel AppEvent
  -> AppModel
  -> WidgetNode AppModel AppEvent
buildUI wenv model = widgetTree where
  widgetTree = vstack [label "This is the title"
                      , textArea_ sampleText [showLineNumbers_ True]
                        `styleBasic` [bgColor $ rgbHex "#204278"
                                     , textFont "Mono"]
                      ]
               `styleBasic` [padding 10]

handleEvent
  :: WidgetEnv AppModel AppEvent
  -> WidgetNode AppModel AppEvent
  -> AppModel
  -> AppEvent
  -> [AppEventResponse AppModel AppEvent]
handleEvent wenv node model evt = case evt of
  AppInit -> []

main09 :: IO ()
main09 = do
  startApp model handleEvent buildUI config
  where
    config = [
      appWindowTitle "Tutorial 09 - TextArea with Linenumbers",
      appWindowIcon "./assets/images/icon2.bmp",
      appTheme darkTheme,
      appFontDef "Regular" "./assets/fonts/Roboto-Regular.ttf",
      appFontDef "Medium" "./assets/fonts/Roboto-Medium.ttf",
      appFontDef "Bold" "./assets/fonts/Roboto-Bold.ttf",
      appFontDef "Italic" "./assets/fonts/Roboto-Italic.ttf",
      appFontDef "Mono" "./assets/fonts/Anonymous_Pro.ttf",
      appFontDef "MonoItalic" "./assets/fonts/Anonymous_Pro_I.ttf",      
      appInitEvent AppInit
      ]
    model = AppModel "Hello World!"
