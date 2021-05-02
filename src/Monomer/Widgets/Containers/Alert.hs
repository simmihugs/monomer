module Monomer.Widgets.Containers.Alert (
  alert,
  alert_,
  alertMsg,
  alertMsg_
) where

import Control.Applicative ((<|>))
import Control.Lens ((&), (.~))
import Data.Default
import Data.Maybe
import Data.Text (Text)

import Monomer.Core
import Monomer.Core.Combinators

import Monomer.Widgets.Composite
import Monomer.Widgets.Containers.Box
import Monomer.Widgets.Containers.Keystroke
import Monomer.Widgets.Containers.Stack
import Monomer.Widgets.Singles.Button
import Monomer.Widgets.Singles.Icon
import Monomer.Widgets.Singles.Label
import Monomer.Widgets.Singles.Spacer

import qualified Monomer.Lens as L

data AlertCfg = AlertCfg {
  _alcTitle :: Maybe Text,
  _alcClose :: Maybe Text
}

instance Default AlertCfg where
  def = AlertCfg {
    _alcTitle = Nothing,
    _alcClose = Nothing
  }

instance Semigroup AlertCfg where
  (<>) a1 a2 = AlertCfg {
    _alcTitle = _alcTitle a2 <|> _alcTitle a1,
    _alcClose = _alcClose a2 <|> _alcClose a1
  }

instance Monoid AlertCfg where
  mempty = def

instance CmbTitleCaption AlertCfg where
  titleCaption t = def {
    _alcTitle = Just t
  }

instance CmbCloseCaption AlertCfg where
  closeCaption t = def {
    _alcClose = Just t
  }

alert
  :: (WidgetModel sp, WidgetEvent ep)
  => WidgetNode () ep
  -> ep
  -> WidgetNode sp ep
alert dialogBody evt = alert_ dialogBody evt def

alert_
  :: (WidgetModel sp, WidgetEvent ep)
  => WidgetNode () ep
  -> ep
  -> [AlertCfg]
  -> WidgetNode sp ep
alert_ dialogBody evt configs = newNode where
  config = mconcat configs
  createUI = buildUI (const dialogBody) evt config
  newNode = compositeExt "alert" () createUI handleEvent

alertMsg
  :: (WidgetModel sp, WidgetEvent ep)
  => Text
  -> ep
  -> WidgetNode sp ep
alertMsg message evt = alertMsg_ message evt def

alertMsg_
  :: (WidgetModel sp, WidgetEvent ep)
  => Text
  -> ep
  -> [AlertCfg]
  -> WidgetNode sp ep
alertMsg_ message evt configs = newNode where
  config = mconcat configs
  dialogBody wenv = label_ message [multiLine]
    & L.info . L.style .~ themeDialogMsgBody wenv
  createUI = buildUI dialogBody evt config
  newNode = compositeExt "alert" () createUI handleEvent

buildUI
  :: WidgetEvent ep
  => (WidgetEnv s ep -> WidgetNode s ep)
  -> ep
  -> AlertCfg
  -> WidgetEnv s ep
  -> s
  -> WidgetNode s ep
buildUI dialogBody cancelEvt config wenv model = mainTree where
  title = fromMaybe "" (_alcTitle config)
  close = fromMaybe "Close" (_alcClose config)
  emptyOverlay = themeEmptyOverlay wenv
  dismissButton = hstack [mainButton close cancelEvt]
  closeIcon = icon IconClose & L.info . L.style .~ themeDialogCloseIcon wenv
  alertTree = vstack_ [sizeReqUpdater clearExtra] [
      hstack [
        label title & L.info . L.style .~ themeDialogTitle wenv,
        filler,
        box_ [alignTop, onClick cancelEvt] closeIcon
      ],
      dialogBody wenv,
      filler,
      box_ [alignLeft] dismissButton
        & L.info . L.style .~ themeDialogButtons wenv
    ] & L.info . L.style .~ themeDialogFrame wenv
  alertBox = box_ [onClickEmpty cancelEvt] alertTree
    & L.info . L.style .~ emptyOverlay
  mainTree = keystroke [("Esc", cancelEvt)] alertBox

handleEvent
  :: WidgetEnv s ep
  -> WidgetNode s ep
  -> s
  -> ep
  -> [EventResponse s e ep]
handleEvent wenv node model evt = [Report evt]